//
//  AccountController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Realm
import RealmSwift

struct AccountCredentials {

  let url: String
  let apiKey: String

}

extension AccountCredentials: Equatable {

  static func ==(lhs: AccountCredentials, rhs: AccountCredentials) -> Bool {
    return lhs.url == rhs.url &&
      lhs.apiKey == rhs.apiKey
  }

}

final class AccountController {

  let uuid: String
  let dataDirectory: URL
  let credentials: AccountCredentials

  var realmFileURL: URL {
    return self.dataDirectory.appendingPathComponent(self.uuid + ".realm")
  }

  init(uuid: String, dataDirectory: URL, credentials: AccountCredentials) {
    self.uuid = uuid
    self.dataDirectory = dataDirectory
    self.credentials = credentials
  }

  private func realmConfiguration() -> Realm.Configuration {
    var config = Realm.Configuration(fileURL: self.realmFileURL)
    config.schemaVersion = 1
    config.migrationBlock = { (migration, oldSchemaVersion) in
      if oldSchemaVersion == 0 {
        self.migrate_0_1(migration)
      }
    }

    return config
  }

  func createRealm() -> Realm {
    let config = self.realmConfiguration()
    let realm = try! Realm(configuration: config)
    return realm
  }

}

extension AccountController: Equatable {

  static func ==(lhs: AccountController, rhs: AccountController) -> Bool {
    return lhs.uuid == rhs.uuid &&
      lhs.credentials == rhs.credentials
  }

}

extension AccountController {

  private func migrate_0_1(_ migration: Migration) {
    // Migrate the apps to new data model
    migration.enumerateObjects(ofType: "MyElectricAppData") { (oldObject, newObject) in
      guard let oldObject = oldObject else { return }

      guard
        let uuid = oldObject.value(forKey: "uuid"),
        let name = oldObject.value(forKey: "name"),
        let useFeedId = oldObject.value(forKey: "useFeedId"),
        let kwhFeedId = oldObject.value(forKey: "kwhFeedId"),
        let feedsJsonData = try? JSONSerialization.data(withJSONObject: ["use":useFeedId, "kwh":kwhFeedId], options: [])
        else {
          return
      }

      let newAppData = migration.create("AppData")
      newAppData.setValue(uuid, forKey: "uuid")
      newAppData.setValue(name, forKey: "name")
      newAppData.setValue(AppCategory.myElectric.rawValue, forKey: "category")
      newAppData.setValue(feedsJsonData, forKey: "feedsJson")
    }
  }

}
