//
//  AccountControllerTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Nimble
import Quick

class AccountControllerTests: QuickSpec {
  override func spec() {
    beforeEach {}

    describe("accountCredentials") {
      it("equality should be true for equal objects") {
        let a = AccountCredentials(url: "url", apiKey: "apiKey")
        let b = AccountCredentials(url: "url", apiKey: "apiKey")
        expect(a == b).to(equal(true))
      }

      it("equality should be false for non-equal objects") {
        let a = AccountCredentials(url: "url", apiKey: "apiKey")
        let b = AccountCredentials(url: "url", apiKey: "notApiKey")
        expect(a == b).to(equal(false))
      }
    }

    describe("accountController") {
      it("equality should be true for equal objects") {
        let credentials = AccountCredentials(url: "url", apiKey: "apiKey")
        let a = AccountController(uuid: "uuid", credentials: credentials)
        let b = AccountController(uuid: "uuid", credentials: credentials)
        expect(a == b).to(equal(true))
      }

      it("equality should be false for non-equal objects") {
        let credentials = AccountCredentials(url: "url", apiKey: "apiKey")
        let a = AccountController(uuid: "uuid1", credentials: credentials)
        let b = AccountController(uuid: "uuid2", credentials: credentials)
        expect(a == b).to(equal(false))
      }
    }
  }
}
