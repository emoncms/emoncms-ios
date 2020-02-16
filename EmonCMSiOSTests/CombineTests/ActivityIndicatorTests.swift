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

class ActivityIndicatorTests: QuickSpec {

  override func spec() {

    var scheduler: TestScheduler!

    beforeEach {
      scheduler = TestScheduler(initialClock: 0)
    }

    describe("ActivityIndicator") {
      it("should track a single publisher") {
        let activityIndicator = ActivityIndicatorCombine()

        scheduler.schedule(after: 250) {
          expect(activityIndicator.loading).to(equal(false))
          let input: TestablePublisher<Int, Never> = scheduler.createRelativeTestablePublisher([
            (10, .completion(.finished))
          ])
          let trackedSubscriber = scheduler.createTestableSubscriber(Int.self, Never.self)
          input.trackActivity(activityIndicator).subscribe(trackedSubscriber)
          expect(activityIndicator.loading).to(equal(true))
        }

        let sut = activityIndicator.asPublisher()
        let results = scheduler.start { sut }

        let expected: TestSequence<Bool, Never> = [
          (200, .subscription),
          (250, .input(true)),
          (260, .input(false)),
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should track a two publishers one after the other") {
        let activityIndicator = ActivityIndicatorCombine()

        scheduler.schedule(after: 250) {
          expect(activityIndicator.loading).to(equal(false))
          let input: TestablePublisher<Int, Never> = scheduler.createRelativeTestablePublisher([
            (10, .completion(.finished))
          ])
          let trackedSubscriber = scheduler.createTestableSubscriber(Int.self, Never.self)
          input.trackActivity(activityIndicator).subscribe(trackedSubscriber)
          expect(activityIndicator.loading).to(equal(true))
        }

        scheduler.schedule(after: 300) {
          expect(activityIndicator.loading).to(equal(false))
          let input: TestablePublisher<Int, Never> = scheduler.createRelativeTestablePublisher([
            (10, .completion(.finished))
          ])
          let trackedSubscriber = scheduler.createTestableSubscriber(Int.self, Never.self)
          input.trackActivity(activityIndicator).subscribe(trackedSubscriber)
          expect(activityIndicator.loading).to(equal(true))
        }

        let sut = activityIndicator.asPublisher()
        let results = scheduler.start { sut }

        let expected: TestSequence<Bool, Never> = [
          (200, .subscription),
          (250, .input(true)),
          (260, .input(false)),
          (300, .input(true)),
          (310, .input(false)),
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should track a two publishers at same time") {
        let activityIndicator = ActivityIndicatorCombine()

        scheduler.schedule(after: 250) {
          expect(activityIndicator.loading).to(equal(false))
          let input: TestablePublisher<Int, Never> = scheduler.createRelativeTestablePublisher([
            (100, .completion(.finished))
          ])
          let trackedSubscriber = scheduler.createTestableSubscriber(Int.self, Never.self)
          input.trackActivity(activityIndicator).subscribe(trackedSubscriber)
          expect(activityIndicator.loading).to(equal(true))
        }

        scheduler.schedule(after: 300) {
          expect(activityIndicator.loading).to(equal(true))
          let input: TestablePublisher<Int, Never> = scheduler.createRelativeTestablePublisher([
            (10, .completion(.finished))
          ])
          let trackedSubscriber = scheduler.createTestableSubscriber(Int.self, Never.self)
          input.trackActivity(activityIndicator).subscribe(trackedSubscriber)
          expect(activityIndicator.loading).to(equal(true))
        }

        let sut = activityIndicator.asPublisher()
        let results = scheduler.start { sut }

        let expected: TestSequence<Bool, Never> = [
          (200, .subscription),
          (250, .input(true)),
          (350, .input(false)),
        ]

        expect(results.recordedOutput).to(equal(expected))
      }
    }

  }

}
