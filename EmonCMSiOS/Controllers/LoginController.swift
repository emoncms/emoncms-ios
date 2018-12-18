//
//  LoginController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import Locksmith

final class LoginController {

  enum LoginControllerError: Error {
    case Generic
    case KeychainFailed
  }

  private var _account = BehaviorRelay<Account?>(value: nil)
  let account: Observable<Account?>

  init() {
    self.account = _account.asObservable().share(replay: 1)
    self.loadAccount()
  }

  private func loadAccount() {
    guard
      let accountURL = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue),
      let accountUUIDString = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue),
      let accountUUID = UUID(uuidString: accountUUIDString)
      else { return }

    guard
      let data = Locksmith.loadDataForUserAccount(userAccount: accountUUIDString),
      let apikey = data["apikey"] as? String
      else { return }

    let account = Account(uuid: accountUUID, url: accountURL, apikey: apikey)
    self._account.accept(account)
  }

  func login(withAccount account: Account) throws {
    do {
      if let currentAccount = _account.value {
        if currentAccount == account {
          return
        }
      }

      let data = ["apikey": account.apikey]
      do {
        try Locksmith.saveData(data: data, forUserAccount: account.uuid.uuidString)
      } catch LocksmithError.duplicate {
        // We already have it, let's try updating it
        try Locksmith.updateData(data: data, forUserAccount: account.uuid.uuidString)
      }
      UserDefaults.standard.set(account.url, forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue)
      UserDefaults.standard.set(account.uuid.uuidString, forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue)
      self._account.accept(account)
    } catch {
      throw LoginControllerError.KeychainFailed
    }
  }

  func logout() throws {
    guard let accountURL = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue) else {
      throw LoginControllerError.Generic
    }
    do {
      try Locksmith.deleteDataForUserAccount(userAccount: accountURL)
      UserDefaults.standard.removeObject(forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue)
      self._account.accept(nil)
    } catch {
      throw LoginControllerError.KeychainFailed
    }
  }

}
