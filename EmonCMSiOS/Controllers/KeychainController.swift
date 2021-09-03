//
//  LoginController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import KeychainAccess

final class KeychainController {
  static let ServiceIdentifier = "org.openenergymonitor.emoncms"
  static let SharedKeychainIdentifier = "4C898RE43H.org.openenergymonitor.emoncms"

  enum KeychainControllerError: Error {
    case generic
    case keychainFailed
  }

  private func keychain(useShared: Bool = false) -> Keychain {
    let keychain: Keychain
    if useShared {
      keychain = Keychain(service: KeychainController.ServiceIdentifier,
                          accessGroup: KeychainController.SharedKeychainIdentifier)
    } else {
      keychain = Keychain(service: KeychainController.ServiceIdentifier)
    }
    return keychain.accessibility(.afterFirstUnlock)
  }

  init() {}

  private func save(data: [String: Any], forUserAccount account: String) throws {
    let keychain = self.keychain()
    let archivedData = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false)
    try keychain.set(archivedData, key: account)
  }

  private func loadData(forUserAccount account: String) throws -> [String: Any] {
    let keychain = self.keychain()
    guard
      let data = try keychain.getData(account),
      let unarchivedData = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data),
      let dict = unarchivedData as? [String: Any]
    else {
      throw KeychainControllerError.generic
    }

    if let attributes = keychain[attributes: account] {
      if attributes.accessible != Accessibility.afterFirstUnlock.rawValue {
        try? self.save(data: dict, forUserAccount: account)
      }
    }

    return dict
  }

  private func deleteData(forUserAccount account: String) throws {
    let keychain = self.keychain()
    try keychain.remove(account)
  }

  func saveAccount(forId id: String, apiKey: String) throws {
    do {
      let data = ["apikey": apiKey]
      try self.save(data: data, forUserAccount: id)
    } catch {
      throw KeychainControllerError.keychainFailed
    }
  }

  func apiKey(forAccountWithId id: String) throws -> String {
    let data: [String: Any]
    do {
      data = try self.loadData(forUserAccount: id)
    } catch {
      throw KeychainControllerError.keychainFailed
    }
    guard let apiKey = data["apikey"] as? String else {
      throw KeychainControllerError.generic
    }
    return apiKey
  }

  func logout(ofAccountWithId id: String) throws {
    do {
      try self.deleteData(forUserAccount: id)
    } catch {
      throw KeychainControllerError.keychainFailed
    }
  }
}
