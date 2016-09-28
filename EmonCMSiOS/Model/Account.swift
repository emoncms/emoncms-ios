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
    let fileURL = URL(fileURLWithPath: RLMRealmPathForFile(self.uuid.uuidString + ".realm"), isDirectory: false)
    var config = Realm.Configuration(fileURL: fileURL)


    //FIXME
    config.deleteRealmIfMigrationNeeded = true


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
