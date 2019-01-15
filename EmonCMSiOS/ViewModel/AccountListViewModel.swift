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
  private(set) var apps: Driver<[ListItem]>

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createRealm()

    self.apps = Driver.never()

    self.migrateOldAccountIfNeeded()

    let appQuery = self.realm.objects(Account.self)
      .sorted(byKeyPath: #keyPath(AppData.name), ascending: true)
    self.apps = Observable.array(from: appQuery)
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

      let realm = realmController.createRealm()
      do {
        try realm.write {
          realm.add(account)
        }
      } catch {}

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

  func mainViewModels(forAccountWithId id: String) ->
    (appList: AppListViewModel, feedList: FeedListViewModel, settings: SettingsViewModel)? {
      guard
        let accountController = self.accountController(forAccountWithId: id)
        else {
          return nil
      }
      let appListViewModel = AppListViewModel(account: accountController, api: self.api)
      let feedListViewModel = FeedListViewModel(account: accountController, api: self.api)
      let settingsViewModel = SettingsViewModel(account: accountController, api: self.api)
      return (appListViewModel, feedListViewModel, settingsViewModel)
  }

  func addAccountViewModel() -> AddAccountViewModel {
    return AddAccountViewModel(realmController: self.realmController, api: self.api)
  }

  func deleteAccount(withId id: String) -> Observable<()> {
    let realm = self.realm
    return Observable.create() { observer in
      do {
        if let account = realm.object(ofType: Account.self, forPrimaryKey: id) {
          try self.keychainController.logout(ofAccountWithId: id)
          try realm.write {
            realm.delete(account)
          }
        }
        observer.onNext(())
        observer.onCompleted()
      } catch {
        observer.onError(error)
      }

      return Disposables.create()
    }
  }

}
