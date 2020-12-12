//
//  AccountListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

final class AccountListViewModel {
  struct ListItem {
    let accountId: String
    let name: String
    let url: String
    let hasApiKey: Bool
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let keychainController: KeychainController
  private let api: EmonCMSAPI
  private let realm: Realm

  private var cancellables = Set<AnyCancellable>()

  // Inputs

  // Outputs
  @Published private(set) var accounts: [ListItem] = []

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createMainRealm()

    self.migrateOldAccountIfNeeded()

    let accountQuery = self.realm.objects(Account.self)
      .sorted(byKeyPath: #keyPath(Account.name), ascending: true)
    accountQuery.collectionPublisher
      .map(self.accountsToListItems)
      .sink(
        receiveCompletion: { error in
          AppLog.error("Query errored when it shouldn't! \(error)")
        },
        receiveValue: { [weak self] items in
          guard let self = self else { return }
          self.accounts = items
        })
      .store(in: &self.cancellables)
  }

  private func migrateOldAccountIfNeeded() {
    if
      let accountURL = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue),
      let accountUUIDString = UserDefaults.standard
      .string(forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue) {
      let account = Account()
      account.uuid = accountUUIDString
      account.name = accountURL
      account.url = accountURL

      let realm = self.realmController.createMainRealm()
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

  private func accountsToListItems(_ accounts: Results<Account>) -> [ListItem] {
    let listItems = accounts.map { account -> ListItem in
      let apiKey = try? self.keychainController.apiKey(forAccountWithId: account.uuid)
      let hasApiKey = apiKey != nil
      return ListItem(accountId: account.uuid, name: account.name, url: account.url, hasApiKey: hasApiKey)
    }
    return Array(listItems)
  }

  private func accountController(forAccountWithId id: String) -> AccountController? {
    guard
      let account = self.realm.object(ofType: Account.self, forPrimaryKey: id),
      let apiKey = try? self.keychainController.apiKey(forAccountWithId: id) else {
      return nil
    }
    let credentials = AccountCredentials(url: account.url, apiKey: apiKey)
    return AccountController(uuid: account.uuid, credentials: credentials)
  }

  var lastSelectedAccountId: String? {
    get {
      return UserDefaults.standard
        .object(forKey: SharedConstants.UserDefaultsKeys.lastSelectedAccountUUID.rawValue) as? String
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
    (appList: AppListViewModel, inputList: InputListViewModel, feedList: FeedListViewModel,
     dashboardList: DashboardListViewModel, settings: SettingsViewModel)? {
    guard
      let accountController = self.accountController(forAccountWithId: id)
    else {
      return nil
    }
    let appListViewModel = AppListViewModel(realmController: self.realmController, account: accountController,
                                            api: self.api)
    let inputListViewModel = InputListViewModel(realmController: self.realmController, account: accountController,
                                                api: self.api)
    let feedListViewModel = FeedListViewModel(realmController: self.realmController, account: accountController,
                                              api: self.api)
    let dashboardListViewModel = DashboardListViewModel(realmController: self.realmController,
                                                        account: accountController, api: self.api)
    let settingsViewModel = SettingsViewModel(realmController: self.realmController, account: accountController,
                                              api: self.api)
    return (appListViewModel, inputListViewModel, feedListViewModel, dashboardListViewModel, settingsViewModel)
  }

  func addAccountViewModel(accountId: String? = nil) -> AddAccountViewModel {
    return AddAccountViewModel(realmController: self.realmController, api: self.api, accountId: accountId)
  }

  func deleteAccount(withId id: String) -> AnyPublisher<Void, Never> {
    let realm = self.realm
    return Deferred { () -> Just<Void> in
      do {
        if let account = realm.object(ofType: Account.self, forPrimaryKey: id) {
          try self.keychainController.logout(ofAccountWithId: id)

          let todayWidgetFeeds = realm.objects(TodayWidgetFeed.self).filter("accountId = %@", account.uuid)
          try realm.write {
            realm.delete(account)
            realm.delete(todayWidgetFeeds)
          }
        }
      } catch {}

      return Just(())
    }.eraseToAnyPublisher()
  }
}
