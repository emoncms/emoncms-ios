//
//  RxOperatorsTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import EntwineTest
@testable import EmonCMSiOS

class RxOperatorsTests: QuickSpec {

  override func spec() {

    var scheduler: TestScheduler!
    
    beforeEach {
      scheduler = TestScheduler(initialClock: 0)
    }

    describe("becomeVoid") {
      it("should work") {
        let publisher: TestablePublisher<Int, Never> = scheduler.createRelativeTestablePublisher([
          (10, .input(1)),
          (20, .input(2)),
          (30, .input(3))
        ])

        let sut = publisher
          .becomeVoid()
          .map {
            return true
          }

        let results = scheduler.start { sut }

        let expected: TestSequence<Bool, Never> = [
          (200, .subscription),
          (210, .input(true)),
          (220, .input(true)),
          (230, .input(true)),
        ]

        expect(results.recordedOutput).to(equal(expected))
      }
    }

  }

}
