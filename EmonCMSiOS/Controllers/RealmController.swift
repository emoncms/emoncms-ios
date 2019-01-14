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

  private func realmConfiguration() -> Realm.Configuration {
    let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.openenergymonitor.emoncms")!
    let fileURL = container.appendingPathComponent("main" + ".realm")
    var config = Realm.Configuration(fileURL: fileURL)
    config.schemaVersion = 1

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

}
