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
    let config = Realm.Configuration(fileURL: fileURL)
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
