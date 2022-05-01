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
  static let schemaVersion: UInt64 = 3

  let dataDirectory: URL

  init(dataDirectory: URL) {
    self.dataDirectory = dataDirectory
  }

  var mainRealmFileURL: URL {
    return self.dataDirectory.appendingPathComponent("main" + ".realm")
  }

  private func mainRealmConfiguration() -> Realm.Configuration {
    var config = Realm.Configuration(fileURL: self.mainRealmFileURL)
    config.schemaVersion = RealmController.schemaVersion
    config.migrationBlock = { migration, oldSchemaVersion in
      if oldSchemaVersion <= 1 {
        self.main_migrate_1_2(migration)
      }
      if oldSchemaVersion <= 2 {
        self.main_migrate_2_3(migration)
      }
    }

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
    config.schemaVersion = RealmController.schemaVersion
    config.migrationBlock = { migration, oldSchemaVersion in
      if oldSchemaVersion == 0 {
        self.account_migrate_0_1(migration)
      }
      if oldSchemaVersion <= 1 {
        self.account_migrate_1_2(migration)
      }
      if oldSchemaVersion <= 2 {
        self.account_migrate_2_3(migration)
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

final class MyElectricAppData: Object {
  @objc dynamic var uuid: String = UUID().uuidString
  @objc dynamic var name: String = "MyElectric"
  @objc dynamic var useFeedId: String?
  @objc dynamic var kwhFeedId: String?

  override class func primaryKey() -> String? {
    return "uuid"
  }
}

extension RealmController {
  private func main_migrate_1_2(_ migration: Migration) {}

  private func main_migrate_2_3(_ migration: Migration) {}
}

extension RealmController {
  private func account_migrate_0_1(_ migration: Migration) {
    // Migrate the apps to new data model
    migration.enumerateObjects(ofType: MyElectricAppData.className()) { oldObject, _ in
      guard let oldObject = oldObject else { return }

      guard
        let uuid = oldObject.value(forKey: "uuid"),
        let name = oldObject.value(forKey: "name"),
        let useFeedId = oldObject.value(forKey: "useFeedId"),
        let kwhFeedId = oldObject.value(forKey: "kwhFeedId"),
        let feedsJsonData = try? JSONSerialization
        .data(withJSONObject: ["use": useFeedId, "kwh": kwhFeedId], options: [])
      else {
        return
      }

      let newAppData = migration.create(AppData.className())
      newAppData.setValue(uuid, forKey: "uuid")
      newAppData.setValue(name, forKey: "name")
      newAppData.setValue(AppCategory.myElectric.rawValue, forKey: "category")
      newAppData.setValue(feedsJsonData, forKey: "feedsJson")
    }
  }

  private func account_migrate_1_2(_ migration: Migration) {}

  private func account_migrate_2_3(_ migration: Migration) {}
}
