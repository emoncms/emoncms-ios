//
//  RealmMigrationTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Foundation
import Nimble
import Quick

class RealmMigrationTests: QuickSpec {
  var dataDirectory: URL {
    return FileManager.default.temporaryDirectory.appendingPathComponent("realm_migration_tests")
  }

  private func copyMainRealm(fromFilename: String, realmController: RealmController) throws {
    guard let oldRealmFileURL = Bundle(for: type(of: self)).url(forResource: fromFilename, withExtension: "realm")
    else {
      throw NSError()
    }
    try FileManager.default
      .createDirectory(at: realmController.dataDirectory, withIntermediateDirectories: true, attributes: nil)
    try FileManager.default.copyItem(at: oldRealmFileURL, to: realmController.mainRealmFileURL)
  }

  private func copyAccountRealm(
    fromFilename: String,
    forAccountId accountId: String,
    realmController: RealmController) throws {
    guard let oldRealmFileURL = Bundle(for: type(of: self)).url(forResource: fromFilename, withExtension: "realm")
    else {
      throw NSError()
    }
    try FileManager.default
      .createDirectory(at: realmController.dataDirectory, withIntermediateDirectories: true, attributes: nil)
    try FileManager.default.copyItem(at: oldRealmFileURL, to: realmController.realmFileURL(forAccountId: accountId))
  }

  override func spec() {
    beforeEach {
      do {
        try FileManager.default.removeItem(at: self.dataDirectory)
        try FileManager.default.removeItem(at: self.dataDirectory)
      } catch {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain, nsError.code == NSFileNoSuchFileError {
          return
        }
        fail("Failed to remove data directory.")
      }
    }

    describe("migrations") {
      var realmController: RealmController!
      var uuid: String!

      beforeEach {
        realmController = RealmController(dataDirectory: self.dataDirectory)
        uuid = UUID().uuidString
      }

      it("should create realms for current schema") {
        do {
          let schemaVersion = RealmController.schemaVersion
          try self.copyMainRealm(fromFilename: "main_v\(schemaVersion)", realmController: realmController)
          try self
            .copyAccountRealm(fromFilename: "account_v\(schemaVersion)", forAccountId: uuid,
                              realmController: realmController)
        } catch {
          fail("Failed to copy Realm file!")
        }

        let mainRealm = realmController.createMainRealm()
        let accountRealm = realmController.createAccountRealm(forAccountId: uuid)

        expect(mainRealm).toNot(beNil())
        expect(accountRealm).toNot(beNil())
      }

      it("main should migrate from v1") {
        do {
          try self.copyMainRealm(fromFilename: "main_v1", realmController: realmController)
        } catch {
          fail("Failed to copy Realm file!")
        }

        let realm = realmController.createMainRealm()
        expect(realm.isEmpty).to(beFalse())
      }

      it("account should migrate from v0") {
        do {
          try self.copyAccountRealm(fromFilename: "account_v0", forAccountId: uuid, realmController: realmController)
        } catch {
          fail("Failed to copy Realm file!")
        }

        let realm = realmController.createAccountRealm(forAccountId: uuid)

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

      it("account should migrate from v1") {
        do {
          try self.copyAccountRealm(fromFilename: "account_v1", forAccountId: uuid, realmController: realmController)
        } catch {
          fail("Failed to copy Realm file!")
        }

        let realm = realmController.createAccountRealm(forAccountId: uuid)
        expect(realm.isEmpty).to(beFalse())
      }
    }
  }
}
