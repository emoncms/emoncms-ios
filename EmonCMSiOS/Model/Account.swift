//
//  EmonCMSAccount.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Realm
import RealmSwift

struct Account {

  let uuid: UUID
  let url: String
  let apikey: String

  private func realmConfiguration() -> Realm.Configuration {
    let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.openenergymonitor.emoncms")!
    let fileURL = container.appendingPathComponent(self.uuid.uuidString + ".realm")
    var config = Realm.Configuration(fileURL: fileURL)

    #if DEBUG
    config.deleteRealmIfMigrationNeeded = true
    #endif

    return config
  }

  func createRealm() -> Realm {
    let config = self.realmConfiguration()
    let realm = try! Realm(configuration: config)
    return realm
  }

  init(uuid: UUID, url: String, apikey: String) {
    self.uuid = uuid
    self.url = url
    self.apikey = apikey
  }

}

extension Account: Equatable {

  static func ==(lhs: Account, rhs: Account) -> Bool {
    return lhs.uuid == rhs.uuid &&
      lhs.url == rhs.url &&
      lhs.apikey == rhs.apikey
  }

}
