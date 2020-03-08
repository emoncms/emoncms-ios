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
        expect { try controller.logout(ofAccountWithId: accountId) }
          .toNot(throwError())
        expect { try controller.saveAccount(forId: accountId, apiKey: apiKey) }
          .toNot(throwError())
        expect { try controller.apiKey(forAccountWithId: accountId) }.to(equal(apiKey))
      }

      it("should logout of account") {
        let accountId = "test_account"
        let apiKey = "test"
        expect { try controller.logout(ofAccountWithId: accountId) }
          .toNot(throwError())
        expect { try controller.saveAccount(forId: accountId, apiKey: apiKey) }
          .toNot(throwError())
        expect { try controller.logout(ofAccountWithId: accountId) }
          .toNot(throwError())
        expect { try controller.apiKey(forAccountWithId: accountId) }.to(throwError())
      }

      it("should update account if already exists") {
        let accountId = "test_account"
        let apiKey1 = "test1"
        let apiKey2 = "test2"
        expect { try controller.logout(ofAccountWithId: accountId) }
          .toNot(throwError())
        expect { try controller.saveAccount(forId: accountId, apiKey: apiKey1) }
          .toNot(throwError())
        expect { try controller.saveAccount(forId: accountId, apiKey: apiKey2) }
          .toNot(throwError())
        expect { try controller.apiKey(forAccountWithId: accountId) }.to(equal(apiKey2))
      }

      it("should throw when account doesn't exist") {
        let accountId = "no_exist_account"
        expect { try controller.apiKey(forAccountWithId: accountId) }.to(throwError())
      }
    }
  }
}
