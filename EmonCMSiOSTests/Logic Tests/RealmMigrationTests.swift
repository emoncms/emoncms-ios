//
//  RealmMigrationTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
@testable import EmonCMSiOS

class RealmMigrationTests: QuickSpec {

  var dataDirectory: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("realm_migration_tests")
  }

  override func spec() {

    describe("accounts") {

      var accountController: AccountController!

      beforeEach {
        let uuid = UUID().uuidString
        let credentials = AccountCredentials(url: "fake", apiKey: "fake")
        accountController = AccountController(uuid: uuid, dataDirectory: self.dataDirectory, credentials: credentials)
      }

      it("should migrate from v0 to v1") {
        guard let oldRealmFileURL = Bundle(for: type(of: self)).url(forResource: "v0", withExtension: "realm") else {
          fail("Failed to find Realm file!")
          return
        }
        try! FileManager.default.createDirectory(at: accountController.dataDirectory, withIntermediateDirectories: true, attributes: nil)
        try! FileManager.default.copyItem(at: oldRealmFileURL, to: accountController.realmFileURL)

        let realm = accountController.createRealm()

        let feeds = realm.objects(Feed.self)
        expect(feeds.count).to(equal(2))

        let apps = realm.objects(AppData.self)
        expect(apps.count).to(equal(1))
        if let app = apps.first {
          expect(app.appCategory).to(equal(AppCategory.myElectric))
          expect(app.name).to(equal("MyElectric"))
          expect(app.feed(forName: "use")).to(equal("1"))
          expect(app.feed(forName: "kwh")).to(equal("2"))
        }
      }
    }

  }

}
