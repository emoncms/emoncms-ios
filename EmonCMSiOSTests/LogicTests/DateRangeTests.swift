//
//  DateRangeTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
@testable import EmonCMSiOS

class DateRangeTests: QuickSpec {

  override func spec() {

    beforeEach {
    }

    describe("calculateDates") {
      it("should calculate -1 hour") {
        let relativeTimestamp = 475372800.0
        let range = DateRange.relative() { $0.hour = -1 }
        let calculatedRange = range.calculateDates(relativeTo: Date(timeIntervalSince1970: relativeTimestamp))
        expect(calculatedRange.0.timeIntervalSince1970).to(equal(475369200.0))
        expect(calculatedRange.1.timeIntervalSince1970).to(equal(relativeTimestamp))
      }

      it("should calculate -8 hour") {
        let relativeTimestamp = 475372800.0
        let range = DateRange.relative() { $0.hour = -8 }
        let calculatedRange = range.calculateDates(relativeTo: Date(timeIntervalSince1970: relativeTimestamp))
        expect(calculatedRange.0.timeIntervalSince1970).to(equal(475344000.0))
        expect(calculatedRange.1.timeIntervalSince1970).to(equal(relativeTimestamp))
      }

      it("should calculate -1 day") {
        let relativeTimestamp = 475372800.0
        let range = DateRange.relative() { $0.day = -1 }
        let calculatedRange = range.calculateDates(relativeTo: Date(timeIntervalSince1970: relativeTimestamp))
        expect(calculatedRange.0.timeIntervalSince1970).to(equal(475286400.0))
        expect(calculatedRange.1.timeIntervalSince1970).to(equal(relativeTimestamp))
      }

      it("should calculate -1 month") {
        let relativeTimestamp = 475372800.0
        let range = DateRange.relative() { $0.month = -1 }
        let calculatedRange = range.calculateDates(relativeTo: Date(timeIntervalSince1970: relativeTimestamp))
        expect(calculatedRange.0.timeIntervalSince1970).to(equal(472694400.0))
        expect(calculatedRange.1.timeIntervalSince1970).to(equal(relativeTimestamp))
      }

      it("should calculate -1 year") {
        let relativeTimestamp = 475372800.0
        let range = DateRange.relative() { $0.year = -1 }
        let calculatedRange = range.calculateDates(relativeTo: Date(timeIntervalSince1970: relativeTimestamp))
        expect(calculatedRange.0.timeIntervalSince1970).to(equal(443750400.0))
        expect(calculatedRange.1.timeIntervalSince1970).to(equal(relativeTimestamp))
      }

      it("should calculate absolute dates") {
        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)
        let range = DateRange.absolute(date1, date2)
        let calculatedRange = range.calculateDates()
        expect(calculatedRange.0).to(equal(date1))
        expect(calculatedRange.1).to(equal(date2))
      }
    }

    describe("1h8hDMYSegmentedControlIndex") {
      it("should convert to and from correctly") {
        for i in 0...4 {
          let dateRange = DateRange.from1h8hDMYSegmentedControlIndex(i)
          switch dateRange {
          case .relative(let dateComponents):
            let index = DateRange.to1h8hDMYSegmentedControlIndex(dateComponents)
            expect(index).to(equal(i))
          default:
            fail("Unexpected case")
          }
        }
      }
    }

    describe("WMYSegmentedControlIndex") {
      it("should convert to and from correctly") {
        for i in 0...2 {
          let dateRange = DateRange.fromWMYSegmentedControlIndex(i)
          switch dateRange {
          case .relative(let dateComponents):
            let index = DateRange.toWMYSegmentedControlIndex(dateComponents)
            expect(index).to(equal(i))
          default:
            fail("Unexpected case")
          }
        }
      }
    }

  }

}
