//
//  LoginController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Locksmith

protocol LoginControllerDelegate: class {

}

class LoginController {

  weak var delegate: LoginControllerDelegate?

  enum LoginControllerError: Error {
    case Generic
    case KeychainFailed
  }

  private(set) var account: Account?

  private enum UserDefaultKeys: String {
    case accountURL
  }

  init() {
    self.loadAccount()
  }

  private func loadAccount() {
    guard let accountURL = UserDefaults.standard.string(forKey: UserDefaultKeys.accountURL.rawValue) else { return }
    guard let data = Locksmith.loadDataForUserAccount(userAccount: accountURL),
      let apikey = data["apikey"] as? String
      else {
        return
    }
    let account = Account(url: accountURL, apikey: apikey)
    self.account = account
  }

  func login(withAccount account: Account) throws {
    do {
      try Locksmith.saveData(data: ["apikey": account.apikey], forUserAccount: account.url)
      UserDefaults.standard.set(account.url, forKey: UserDefaultKeys.accountURL.rawValue)
      self.account = account
    } catch {
      throw LoginControllerError.KeychainFailed
    }
  }

  func logout() throws {
    guard let accountURL = UserDefaults.standard.string(forKey: UserDefaultKeys.accountURL.rawValue) else {
      throw LoginControllerError.Generic
    }
    do {
      try Locksmith.deleteDataForUserAccount(userAccount: accountURL)
      UserDefaults.standard.removeObject(forKey: UserDefaultKeys.accountURL.rawValue)
      self.account = nil
    } catch {
      throw LoginControllerError.KeychainFailed
    }
  }

}
