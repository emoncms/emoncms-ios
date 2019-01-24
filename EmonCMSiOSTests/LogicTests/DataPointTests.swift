//
//  DataPointTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
@testable import EmonCMSiOS

class DataPointTests: QuickSpec {

  override func spec() {

    beforeEach {
    }

    describe("merge") {
      it("should merge points with all same times") {
        let a = [
          DataPoint(time: Date(timeIntervalSince1970: 0), value: 10),
          DataPoint(time: Date(timeIntervalSince1970: 1), value: 11),
          DataPoint(time: Date(timeIntervalSince1970: 2), value: 12),
          DataPoint(time: Date(timeIntervalSince1970: 3), value: 13),
          DataPoint(time: Date(timeIntervalSince1970: 5), value: 14),
        ]

        let b = [
          DataPoint(time: Date(timeIntervalSince1970: 0), value: 20),
          DataPoint(time: Date(timeIntervalSince1970: 1), value: 21),
          DataPoint(time: Date(timeIntervalSince1970: 2), value: 22),
          DataPoint(time: Date(timeIntervalSince1970: 3), value: 23),
          DataPoint(time: Date(timeIntervalSince1970: 5), value: 24),
        ]

        let c = [
          DataPoint(time: Date(timeIntervalSince1970: 0), value: 30),
          DataPoint(time: Date(timeIntervalSince1970: 1), value: 31),
          DataPoint(time: Date(timeIntervalSince1970: 2), value: 32),
          DataPoint(time: Date(timeIntervalSince1970: 3), value: 33),
          DataPoint(time: Date(timeIntervalSince1970: 5), value: 34),
        ]

        var out = [(TimeInterval, Date, [Int])]()
        DataPoint<Int>.merge(pointsFrom: [a, b, c]) { out.append(($0, $1, $2)) }

        let expected: [(TimeInterval, Date, [Int])] = [
          (0, Date(timeIntervalSince1970: 0), [10, 20, 30]),
          (1, Date(timeIntervalSince1970: 1), [11, 21, 31]),
          (1, Date(timeIntervalSince1970: 2), [12, 22, 32]),
          (1, Date(timeIntervalSince1970: 3), [13, 23, 33]),
          (2, Date(timeIntervalSince1970: 5), [14, 24, 34]),
        ]

        // Nimble seems to get confused on the `[(TimeInterval, Date, [Double])]` type, so we have to do this
        expect(out.map{$0.0}).to(equal(expected.map{$0.0}))
        expect(out.map{$0.1}).to(equal(expected.map{$0.1}))
        expect(out.map{$0.2}).to(equal(expected.map{$0.2}))
      }

      it("should merge points with some different times") {
        let a = [
          DataPoint(time: Date(timeIntervalSince1970: 0), value: 10),
          DataPoint(time: Date(timeIntervalSince1970: 1), value: 11),
          DataPoint(time: Date(timeIntervalSince1970: 2), value: 12),
          DataPoint(time: Date(timeIntervalSince1970: 6), value: 13),
          DataPoint(time: Date(timeIntervalSince1970: 7), value: 14),
        ]

        let b = [
          DataPoint(time: Date(timeIntervalSince1970: 0), value: 20),
          DataPoint(time: Date(timeIntervalSince1970: 1), value: 21),
          DataPoint(time: Date(timeIntervalSince1970: 3), value: 22),
          DataPoint(time: Date(timeIntervalSince1970: 7), value: 23),
          DataPoint(time: Date(timeIntervalSince1970: 9), value: 24),
        ]

        let c = [
          DataPoint(time: Date(timeIntervalSince1970: 0), value: 30),
          DataPoint(time: Date(timeIntervalSince1970: 1), value: 31),
          DataPoint(time: Date(timeIntervalSince1970: 7), value: 32),
          DataPoint(time: Date(timeIntervalSince1970: 8), value: 33),
          DataPoint(time: Date(timeIntervalSince1970: 10), value: 34),
        ]

        var out = [(TimeInterval, Date, [Int])]()
        DataPoint<Int>.merge(pointsFrom: [a, b, c]) { out.append(($0, $1, $2)) }

        let expected: [(TimeInterval, Date, [Int])] = [
          (0, Date(timeIntervalSince1970: 0), [10, 20, 30]),
          (1, Date(timeIntervalSince1970: 1), [11, 21, 31]),
          (6, Date(timeIntervalSince1970: 7), [14, 23, 32]),
        ]

        // Nimble seems to get confused on the `[(TimeInterval, Date, [Double])]` type, so we have to do this
        expect(out.map{$0.0}).to(equal(expected.map{$0.0}))
        expect(out.map{$0.1}).to(equal(expected.map{$0.1}))
        expect(out.map{$0.2}).to(equal(expected.map{$0.2}))
      }

      it("should merge points with all different times") {
        let a = [
          DataPoint(time: Date(timeIntervalSince1970: 0), value: 10),
          DataPoint(time: Date(timeIntervalSince1970: 1), value: 11),
          DataPoint(time: Date(timeIntervalSince1970: 2), value: 12),
          DataPoint(time: Date(timeIntervalSince1970: 3), value: 13),
          DataPoint(time: Date(timeIntervalSince1970: 5), value: 14),
        ]

        let b = [
          DataPoint(time: Date(timeIntervalSince1970: 6), value: 20),
          DataPoint(time: Date(timeIntervalSince1970: 7), value: 21),
          DataPoint(time: Date(timeIntervalSince1970: 8), value: 22),
          DataPoint(time: Date(timeIntervalSince1970: 9), value: 23),
          DataPoint(time: Date(timeIntervalSince1970: 10), value: 24),
        ]

        let c = [
          DataPoint(time: Date(timeIntervalSince1970: 11), value: 30),
          DataPoint(time: Date(timeIntervalSince1970: 12), value: 31),
          DataPoint(time: Date(timeIntervalSince1970: 13), value: 32),
          DataPoint(time: Date(timeIntervalSince1970: 14), value: 33),
          DataPoint(time: Date(timeIntervalSince1970: 15), value: 34),
        ]

        var out = [(TimeInterval, Date, [Int])]()
        DataPoint<Int>.merge(pointsFrom: [a, b, c]) { out.append(($0, $1, $2)) }

        let expected: [(TimeInterval, Date, [Int])] = [
        ]

        // Nimble seems to get confused on the `[(TimeInterval, Date, [Double])]` type, so we have to do this
        expect(out.map{$0.0}).to(equal(expected.map{$0.0}))
        expect(out.map{$0.1}).to(equal(expected.map{$0.1}))
        expect(out.map{$0.2}).to(equal(expected.map{$0.2}))
      }
    }
    
  }

}
