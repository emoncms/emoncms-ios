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

  static let ServiceIdentifier = "org.openenergymonitor.emoncms"

  enum KeychainControllerError: Error {
    case Generic
    case KeychainFailed
  }

  struct AccountSecureStorable:
    ReadableSecureStorable,
    CreateableSecureStorable,
    DeleteableSecureStorable,
    GenericPasswordSecureStorable
  {
    let service = KeychainController.ServiceIdentifier
    let account: String
    var data: [String:Any]
  }

  init() {
  }

  private func save(data: [String:Any], forUserAccount account: String) throws {
    let storable = AccountSecureStorable(account: account, data: data)
    try storable.createInSecureStore()
  }

  private func update(data: [String:Any], forUserAccount account: String) throws {
    let storable = AccountSecureStorable(account: account, data: data)
    try storable.updateInSecureStore()
  }

  private func loadData(forUserAccount account: String) -> [String:Any]? {
    let storable = AccountSecureStorable(account: account, data: [:])
    return storable.readFromSecureStore()?.data
  }

  private func deleteData(forUserAccount account: String) throws {
    let storable = AccountSecureStorable(account: account, data: [:])
    try storable.deleteFromSecureStore()
  }

  func saveAccount(forId id: String, apiKey: String) throws {
    do {
      let data = ["apikey": apiKey]
      do {
        try self.save(data: data, forUserAccount: id)
      } catch LocksmithError.duplicate {
        // We already have it, let's try updating it
        try self.update(data: data, forUserAccount: id)
      }
    } catch {
      throw KeychainControllerError.KeychainFailed
    }
  }

  func apiKey(forAccountWithId id: String) -> String? {
    guard
      let data = self.loadData(forUserAccount: id),
      let apiKey = data["apikey"] as? String else {
        return nil
    }
    return apiKey
  }

  func logout(ofAccountWithId id: String) throws {
    do {
      try self.deleteData(forUserAccount: id)
    } catch LocksmithError.notFound {
      // This is OK - it wasn't there anyway
    } catch {
      throw KeychainControllerError.KeychainFailed
    }
  }

}
