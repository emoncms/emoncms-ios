//
//  LoginController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Realm
import RealmSwift
import RxSwift
import RxCocoa
import Locksmith

final class LoginController {

  private let realmController: RealmController

  enum LoginControllerError: Error {
    case Generic
    case KeychainFailed
  }

  private var _account = BehaviorRelay<AccountRealmController?>(value: nil)
  let account: Observable<AccountRealmController?>

  init(realmController: RealmController) {
    self.realmController = realmController
    self.account = _account.asObservable().share(replay: 1)
    self.loadAccount()
  }

  private func loadAccount() {
    let realm = realmController.createRealm()

    // Migrate account to Realm if needed
    if
      let accountURL = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue),
      let accountUUIDString = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue)
    {
      let account = Account()
      account.uuid = accountUUIDString
      account.url = accountURL

      do {
        try realm.write {
          realm.add(account)
        }
      } catch {}

      UserDefaults.standard.removeObject(forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue)
      UserDefaults.standard.removeObject(forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue)
    }

    let accounts = realm.objects(Account.self)
    if let account = accounts.first {
      guard
        let accountUUID = UUID(uuidString: account.uuid),
        let data = Locksmith.loadDataForUserAccount(userAccount: account.uuid),
        let apikey = data["apikey"] as? String
        else { return }

      let accountController = AccountRealmController(uuid: accountUUID, url: account.url, apikey: apikey)
      self._account.accept(accountController)
    }
  }

  func login(withAccount accountController: AccountRealmController) throws {
    let realm = realmController.createRealm()

    do {
      if let currentAccountController = _account.value {
        if currentAccountController == accountController {
          return
        }
      }

      let data = ["apikey": accountController.apikey]
      do {
        try Locksmith.saveData(data: data, forUserAccount: accountController.uuid.uuidString)
      } catch LocksmithError.duplicate {
        // We already have it, let's try updating it
        try Locksmith.updateData(data: data, forUserAccount: accountController.uuid.uuidString)
      }

      let account = Account()
      account.uuid = accountController.uuid.uuidString
      account.url = accountController.url

      try realm.write {
        realm.add(account)
      }

      self._account.accept(accountController)
    } catch {
      throw LoginControllerError.KeychainFailed
    }
  }

  func logout() throws {
    let realm = realmController.createRealm()

    let accounts = realm.objects(Account.self)
    guard let account = accounts.first else {
      throw LoginControllerError.Generic
    }

    do {
      try Locksmith.deleteDataForUserAccount(userAccount: account.uuid)
      try realm.write {
        realm.delete(account)
      }
      self._account.accept(nil)
    } catch {
      throw LoginControllerError.KeychainFailed
    }
  }

}
