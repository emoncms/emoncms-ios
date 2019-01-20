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

  var realmFileURL: URL {
    return self.dataDirectory.appendingPathComponent("main" + ".realm")
  }

  init(dataDirectory: URL) {
    self.dataDirectory = dataDirectory
  }

  private func realmConfiguration() -> Realm.Configuration {
    var config = Realm.Configuration(fileURL: self.realmFileURL)
    config.schemaVersion = 1
    return config
  }

  func createRealm() -> Realm {
    let config = self.realmConfiguration()
    let realm = try! Realm(configuration: config)
    return realm
  }

}
