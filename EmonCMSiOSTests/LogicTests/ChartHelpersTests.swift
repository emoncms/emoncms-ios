//
//  ChartHelpersTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 04/04/2022.
//  Copyright © 2022 Matt Galloway. All rights reserved.
//

import Charts
@testable import EmonCMSiOS
import Foundation
import Nimble
import Quick

class ChartHelpersTests: QuickSpec {
  override func spec() {
    beforeEach {}

    describe("chartHelpers") {
      it("should process full kwh data correctly") {
        let startDate = Date(timeIntervalSince1970: 946684800)
        let interval: TimeInterval = 86400
        let dataPoints = [
          DataPoint<Double>(time: startDate + (interval * 0), value: 0),
          DataPoint<Double>(time: startDate + (interval * 1), value: 10),
          DataPoint<Double>(time: startDate + (interval * 2), value: 15),
          DataPoint<Double>(time: startDate + (interval * 3), value: 17),
          DataPoint<Double>(time: startDate + (interval * 4), value: 20),
          DataPoint<Double>(time: startDate + (interval * 5), value: 30)
        ]

        let processed = ChartHelpers.processKWHData(dataPoints, padTo: 5, interval: interval)

        let expected = [
          DataPoint<Double>(time: startDate + (interval * 1), value: 10),
          DataPoint<Double>(time: startDate + (interval * 2), value: 5),
          DataPoint<Double>(time: startDate + (interval * 3), value: 2),
          DataPoint<Double>(time: startDate + (interval * 4), value: 3),
          DataPoint<Double>(time: startDate + (interval * 5), value: 10)
        ]
        expect(processed).to(equal(expected))
      }

      it("should process padded kwh data correctly") {
        let startDate = Date(timeIntervalSince1970: 946684800)
        let interval: TimeInterval = 86400
        let dataPoints = [
          DataPoint<Double>(time: startDate + (interval * 3), value: 17),
          DataPoint<Double>(time: startDate + (interval * 4), value: 20),
          DataPoint<Double>(time: startDate + (interval * 5), value: 30)
        ]

        let processed = ChartHelpers.processKWHData(dataPoints, padTo: 5, interval: interval)

        let expected = [
          DataPoint<Double>(time: startDate + (interval * 1), value: 0),
          DataPoint<Double>(time: startDate + (interval * 2), value: 0),
          DataPoint<Double>(time: startDate + (interval * 3), value: 17),
          DataPoint<Double>(time: startDate + (interval * 4), value: 3),
          DataPoint<Double>(time: startDate + (interval * 5), value: 10)
        ]
        expect(processed).to(equal(expected))
      }

      it("should process single kwh data correctly") {
        let startDate = Date(timeIntervalSince1970: 946684800)
        let interval: TimeInterval = 86400
        let dataPoints = [
          DataPoint<Double>(time: startDate + (interval * 5), value: 30)
        ]

        let processed = ChartHelpers.processKWHData(dataPoints, padTo: 5, interval: interval)

        let expected = [
          DataPoint<Double>(time: startDate + (interval * 1), value: 0),
          DataPoint<Double>(time: startDate + (interval * 2), value: 0),
          DataPoint<Double>(time: startDate + (interval * 3), value: 0),
          DataPoint<Double>(time: startDate + (interval * 4), value: 0),
          DataPoint<Double>(time: startDate + (interval * 5), value: 30)
        ]
        expect(processed).to(equal(expected))
      }
    }
  }
}
