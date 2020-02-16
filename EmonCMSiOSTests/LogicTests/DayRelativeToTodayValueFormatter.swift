//
//  DayRelativeToTodayValueFormatterTests.swift
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

class DayRelativeToTodayValueFormatterTests: QuickSpec {
  override func spec() {
    beforeEach {}

    describe("dayRelativeToTodayValueFormatter") {
      it("should format properly for 7 day week") {
        let formatter = DayRelativeToTodayValueFormatter(relativeTo: Date(timeIntervalSince1970: 86400 * 7))
        let axis = AxisBase()
        axis.axisRange = 7

        let values = (-7 ... 0)
          .map { formatter.stringForValue(Double($0), axis: axis) }

        expect(values).to(equal(["T", "F", "S", "S", "M", "T", "W", "T"]))
      }

      it("should format properly for month") {
        let formatter = DayRelativeToTodayValueFormatter(relativeTo: Date(timeIntervalSince1970: 86400 * 31))
        let axis = AxisBase()
        axis.axisRange = 31

        let values = (-31 ... 0)
          .map { formatter.stringForValue(Double($0), axis: axis) }

        expect(values).to(equal(["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "01"]))
      }

      it("should format properly for year") {
        let formatter = DayRelativeToTodayValueFormatter(relativeTo: Date(timeIntervalSince1970: 86400 * 365))
        let axis = AxisBase()
        axis.axisRange = 365

        let values = [-365, -61, -15, 0]
          .map { formatter.stringForValue(Double($0), axis: axis) }

        expect(values).to(equal(["Jan 01", "Nov 01", "Dec 17", "Jan 01"]))
      }
    }
  }
}
