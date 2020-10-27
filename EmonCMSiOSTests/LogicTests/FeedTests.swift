//
//  FeedTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 27/10/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Foundation
import Nimble
import Quick

class FeedTests: QuickSpec {
  override func spec() {
    beforeEach {}

    describe("widgetChartPoints") {
      it("should save and restore correctly") {
        let dataPoints = [
          DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 1.0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 2.0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3.0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 4.0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 5.0)
        ]

        let feed = Feed()
        feed.widgetChartPoints = dataPoints

        expect(feed.widgetChartPoints).to(equal(dataPoints))
      }
    }
  }
}
