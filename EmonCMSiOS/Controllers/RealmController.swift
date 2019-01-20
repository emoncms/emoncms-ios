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

  private func realmConfiguration() -> Realm.Configuration {
    let fileURL = self.dataDirectory.appendingPathComponent("main" + ".realm")
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
