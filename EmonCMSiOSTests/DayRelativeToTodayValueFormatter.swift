//
//  DayRelativeToTodayValueFormatterTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
@testable import EmonCMSiOS

class DayRelativeToTodayValueFormatterTests: QuickSpec {

  override func spec() {

    beforeEach {
    }

    describe("dayRelativeToTodayValueFormatter") {
      it("should format properly") {
        let formatter = DayRelativeToTodayValueFormatter()

        let values = (-6...0)
          .map {
            formatter.stringForValue(Double($0), axis: nil)
          }
          .sorted()

        expect(values).to(equal(["F", "M", "S", "S", "T", "T", "W"]))
      }
    }

  }

}
