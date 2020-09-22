//
//  KeychainControllerTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Nimble
import Quick

class KeychainControllerTests: QuickSpec {
  override func spec() {
    var controller: KeychainController!

    beforeEach {
      controller = KeychainController()
    }

    describe("keychainController") {
      it("should save account") {
        let accountId = "test_account"
        let apiKey = "test"
        do {
          try controller.logout(ofAccountWithId: accountId)
          try controller.saveAccount(forId: accountId, apiKey: apiKey)
          let fetchedKey = try controller.apiKey(forAccountWithId: accountId)
          expect(fetchedKey).to(equal(apiKey))
        } catch {
          fail("Shouldn't throw")
        }
      }

      it("should logout of account") {
        let accountId = "test_account"
        let apiKey = "test"

        do {
          try controller.logout(ofAccountWithId: accountId)
          try controller.saveAccount(forId: accountId, apiKey: apiKey)
          try controller.logout(ofAccountWithId: accountId)
        } catch {
          fail("Shouldn't throw")
        }

        var threw = false
        do {
          _ = try controller.apiKey(forAccountWithId: accountId)
        } catch {
          threw = true
        }
        expect(threw).to(equal(true))
      }

      it("should update account if already exists") {
        let accountId = "test_account"
        let apiKey1 = "test1"
        let apiKey2 = "test2"

        do {
          try controller.logout(ofAccountWithId: accountId)
          try controller.saveAccount(forId: accountId, apiKey: apiKey1)
          try controller.saveAccount(forId: accountId, apiKey: apiKey2)
          let fetchedKey = try controller.apiKey(forAccountWithId: accountId)
          expect(fetchedKey).to(equal(apiKey2))
        } catch {
          fail("Shouldn't throw")
        }
      }

      it("should throw when account doesn't exist") {
        let accountId = "no_exist_account"
        var threw = false
        do {
          _ = try controller.apiKey(forAccountWithId: accountId)
        } catch {
          threw = true
        }
        expect(threw).to(equal(true))
      }
    }
  }
}
