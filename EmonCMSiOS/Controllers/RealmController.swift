//
//  RealmController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import Realm
import RealmSwift

final class RealmController {

  let dataDirectory: URL

  init(dataDirectory: URL) {
    self.dataDirectory = dataDirectory
  }

  var mainRealmFileURL: URL {
    return self.dataDirectory.appendingPathComponent("main" + ".realm")
  }

  private func mainRealmConfiguration() -> Realm.Configuration {
    var config = Realm.Configuration(fileURL: self.mainRealmFileURL)
    config.schemaVersion = 1
    return config
  }

  func createMainRealm() -> Realm {
    let config = self.mainRealmConfiguration()
    let realm = try! Realm(configuration: config)
    return realm
  }

  func realmFileURL(forAccountId accountId: String) -> URL {
    return self.dataDirectory.appendingPathComponent(accountId + ".realm")
  }

  private func accountRealmConfiguration(forAccountId accountId: String) -> Realm.Configuration {
    var config = Realm.Configuration(fileURL: self.realmFileURL(forAccountId: accountId))
    config.schemaVersion = 1
    config.migrationBlock = { (migration, oldSchemaVersion) in
      if oldSchemaVersion == 0 {
        self.account_migrate_0_1(migration)
      }
    }

    return config
  }

  func createAccountRealm(forAccountId accountId: String) -> Realm {
    let config = self.accountRealmConfiguration(forAccountId: accountId)
    let realm = try! Realm(configuration: config)
    return realm
  }

}

extension RealmController {

  private func account_migrate_0_1(_ migration: Migration) {
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
