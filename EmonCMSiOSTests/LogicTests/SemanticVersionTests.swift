//
//  SemanticVersionTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 29/04/2022.
//  Copyright © 2022 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Nimble
import Quick

class SemanticVersionTests: QuickSpec {
  override func spec() {
    beforeEach {}

    describe("semanticVersion") {
      it("equality should be true for equal objects") {
        let a = SemanticVersion(major: 1, minor: 2, patch: 3)
        let b = SemanticVersion(major: 1, minor: 2, patch: 3)
        expect(a == b).to(equal(true))
      }

      it("equality should be false for non-equal objects") {
        let a = SemanticVersion(major: 1, minor: 2, patch: 3)
        let b = SemanticVersion(major: 2, minor: 3, patch: 4)
        expect(a == b).to(equal(false))
      }

      it("different major versions should order correctly") {
        let a = SemanticVersion(major: 1, minor: 0, patch: 0)
        let b = SemanticVersion(major: 2, minor: 0, patch: 0)
        expect(a < b).to(equal(true))
        expect(a > b).to(equal(false))
      }

      it("different minor versions should order correctly") {
        let a = SemanticVersion(major: 0, minor: 1, patch: 0)
        let b = SemanticVersion(major: 0, minor: 2, patch: 0)
        expect(a < b).to(equal(true))
        expect(a > b).to(equal(false))
      }

      it("different patch versions should order correctly") {
        let a = SemanticVersion(major: 0, minor: 0, patch: 1)
        let b = SemanticVersion(major: 0, minor: 0, patch: 2)
        expect(a < b).to(equal(true))
        expect(a > b).to(equal(false))
      }

      it("convert to string correctly") {
        let a = SemanticVersion(major: 1, minor: 2, patch: 3)
        let string = a.string
        expect(string).to(equal("1.2.3"))
      }
    }
  }
}
