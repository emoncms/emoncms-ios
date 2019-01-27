//
//  LoginController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Locksmith

final class KeychainController {

  enum KeychainControllerError: Error {
    case Generic
    case KeychainFailed
  }

  init() {
  }

  func saveAccount(forId id: String, apiKey: String) throws {
    do {
      let data = ["apikey": apiKey]
      do {
        try Locksmith.saveData(data: data, forUserAccount: id)
      } catch LocksmithError.duplicate {
        // We already have it, let's try updating it
        try Locksmith.updateData(data: data, forUserAccount: id)
      }
    } catch {
      throw KeychainControllerError.KeychainFailed
    }
  }

  func apiKey(forAccountWithId id: String) -> String? {
    guard
      let data = Locksmith.loadDataForUserAccount(userAccount: id),
      let apiKey = data["apikey"] as? String else {
        return nil
    }
    return apiKey
  }

  func logout(ofAccountWithId id: String) throws {
    do {
      try Locksmith.deleteDataForUserAccount(userAccount: id)
    } catch LocksmithError.notFound {
      // This is OK - it wasn't there anyway
    } catch {
      throw KeychainControllerError.KeychainFailed
    }
  }

}
