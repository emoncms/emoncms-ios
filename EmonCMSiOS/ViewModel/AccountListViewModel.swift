//
//  AccountListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import RxRealm

final class AccountListViewModel {

  struct ListItem {
    let accountId: String
    let name: String
    let url: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let keychainController: KeychainController
  private let api: EmonCMSAPI
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs

  // Outputs
  private(set) var accounts: Driver<[ListItem]>

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createMainRealm()

    self.accounts = Driver.never()

    self.migrateOldAccountIfNeeded()

    let accountQuery = self.realm.objects(Account.self)
      .sorted(byKeyPath: #keyPath(Account.name), ascending: true)
    self.accounts = Observable.array(from: accountQuery)
      .map(self.accountsToListItems)
      .asDriver(onErrorJustReturn: [])
  }

  private func migrateOldAccountIfNeeded() {
    if
      let accountURL = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue),
      let accountUUIDString = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue)
    {
      let account = Account()
      account.uuid = accountUUIDString
      account.name = accountURL
      account.url = accountURL

      let realm = realmController.createMainRealm()
      let existingObject = realm.object(ofType: Account.self, forPrimaryKey: accountUUIDString)
      if existingObject == nil {
        do {
          try realm.write {
            realm.add(account)
          }
        } catch {}
      }

      UserDefaults.standard.removeObject(forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue)
      UserDefaults.standard.removeObject(forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue)
    }
  }

  private func accountsToListItems(_ accounts: [Account]) -> [ListItem] {
    let listItems = accounts.map {
      ListItem(accountId: $0.uuid, name: $0.name, url: $0.url)
    }
    return listItems
  }

  private func accountController(forAccountWithId id: String) -> AccountController? {
    guard
      let account = self.realm.object(ofType: Account.self, forPrimaryKey: id),
      let apiKey = self.keychainController.apiKey(forAccountWithId: id) else {
        return nil
    }
    let credentials = AccountCredentials(url: account.url, apiKey: apiKey)
    return AccountController(uuid: account.uuid, credentials: credentials)
  }

  var lastSelectedAccountId: String? {
    get {
      return UserDefaults.standard.object(forKey: SharedConstants.UserDefaultsKeys.lastSelectedAccountUUID.rawValue) as? String
    }
    set {
      if let newValue = newValue {
        UserDefaults.standard.set(newValue, forKey: SharedConstants.UserDefaultsKeys.lastSelectedAccountUUID.rawValue)
      } else {
        UserDefaults.standard.removeObject(forKey: SharedConstants.UserDefaultsKeys.lastSelectedAccountUUID.rawValue)
      }
    }
  }

  func mainViewModels(forAccountWithId id: String) ->
    (appList: AppListViewModel, inputList: InputListViewModel, feedList: FeedListViewModel, dashboardList: DashboardListViewModel, settings: SettingsViewModel)? {
      guard
        let accountController = self.accountController(forAccountWithId: id)
        else {
          return nil
      }
      let appListViewModel = AppListViewModel(realmController: self.realmController, account: accountController, api: self.api)
      let inputListViewModel = InputListViewModel(realmController: self.realmController, account: accountController, api: self.api)
      let feedListViewModel = FeedListViewModel(realmController: self.realmController, account: accountController, api: self.api)
      let dashboardListViewModel = DashboardListViewModel(realmController: self.realmController, account: accountController, api: self.api)
      let settingsViewModel = SettingsViewModel(realmController: self.realmController, account: accountController, api: self.api)
      return (appListViewModel, inputListViewModel, feedListViewModel, dashboardListViewModel, settingsViewModel)
  }

  func addAccountViewModel(accountId: String? = nil) -> AddAccountViewModel {
    return AddAccountViewModel(realmController: self.realmController, api: self.api, accountId: accountId)
  }

  func deleteAccount(withId id: String) -> Observable<()> {
    let realm = self.realm
    return Observable.deferred {
      if let account = realm.object(ofType: Account.self, forPrimaryKey: id) {
        try self.keychainController.logout(ofAccountWithId: id)

        let todayWidgetFeeds = realm.objects(TodayWidgetFeed.self).filter("accountId = %@", account.uuid)
        try realm.write {
          realm.delete(account)
          realm.delete(todayWidgetFeeds)
        }
      }

      return Observable.just(())
    }
  }

}
