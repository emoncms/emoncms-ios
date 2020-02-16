//
//  EmoncmsDoubleTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 16/02/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import EmonCMSiOS

class EmoncmsDoubleTests: QuickSpec {

  override func spec() {

    describe("double conversion") {
      it("should convert float correctly") {
        let float: Float = 1.0
        let double = Double.from(float)
        expect(double).toNot(beNil())
        expect(double).to(equal(1.0))
      }

      it("should convert int correctly") {
        let int: Int = 1
        let double = Double.from(int)
        expect(double).toNot(beNil())
        expect(double).to(equal(1.0))
      }

      it("should convert string correctly") {
        let string: String = "1"
        let double = Double.from(string)
        expect(double).toNot(beNil())
        expect(double).to(equal(1.0))
      }

      it("should convert invalid string correctly") {
        let string: String = "1not1"
        let double = Double.from(string)
        expect(double).to(beNil())
      }

      it("should convert other type correctly") {
        let array: [Int] = []
        let double = Double.from(array)
        expect(double).to(beNil())
      }
    }

    describe("pretty format") {
      it("should auto-format with two decimals correctly") {
        let number = 5.123
        let string = number.prettyFormat()
        expect(string).to(equal("5.12"))
      }

      it("should auto-format with one decimals correctly") {
        let number = 12.123
        let string = number.prettyFormat()
        expect(string).to(equal("12.1"))
      }

      it("should auto-format with no decimals correctly") {
        let number = 123.123
        let string = number.prettyFormat()
        expect(string).to(equal("123"))
      }

      it("should format when decimals specified correctly") {
        let number = 123.1234567
        expect(number.prettyFormat(decimals: 0)).to(equal("123"))
        expect(number.prettyFormat(decimals: 1)).to(equal("123.1"))
        expect(number.prettyFormat(decimals: 2)).to(equal("123.12"))
        expect(number.prettyFormat(decimals: 3)).to(equal("123.123"))
        expect(number.prettyFormat(decimals: 4)).to(equal("123.1235"))
        expect(number.prettyFormat(decimals: 5)).to(equal("123.12346"))
      }
    }

  }

}
