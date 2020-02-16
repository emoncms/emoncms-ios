//
//  ChartDateValueFormatterTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Charts
@testable import EmonCMSiOS
import Foundation
import Nimble
import Quick

class ChartDateValueFormatterTests: QuickSpec {
  override func spec() {
    beforeEach {}

    describe("chartDateValueFormatter") {
      it("should format properly for auto type") {
        let formatter = ChartDateValueFormatter(.auto)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        let axis = AxisBase()

        axis.axisRange = 1000
        expect(formatter.stringForValue(0, axis: axis)).to(equal("12:00 AM"))

        axis.axisRange = 1000000
        expect(formatter.stringForValue(0, axis: axis)).to(equal("1/1"))

        axis.axisRange = 1000000000
        expect(formatter.stringForValue(0, axis: axis)).to(equal("1/1/70"))
      }

      it("should format properly for fixed format") {
        let formatter = ChartDateValueFormatter(.format("dd/MM/yyyy HH:mm:ss"))
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        expect(formatter.stringForValue(0, axis: nil)).to(equal("01/01/1970 00:00:00"))
      }

      it("should format properly with a given formatter") {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"

        let formatter = ChartDateValueFormatter(.formatter(dateFormatter))
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        expect(formatter.stringForValue(0, axis: nil)).to(equal("01/01/1970 00:00:00"))
      }
    }
  }
}
