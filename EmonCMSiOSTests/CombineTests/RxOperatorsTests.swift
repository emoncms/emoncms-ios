//
//  RxOperatorsTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Combine
import Nimble
import EntwineTest
@testable import EmonCMSiOS

enum TestError: Error {
  case generic
}

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

    describe("Producer") {
      it("should send values") {
        var observer: Producer<Int, Never>.Subscriber!
        let producer = Producer<Int, Never> { o in
          observer = o
        }

        scheduler.schedule(after: 210) { _ = observer.receive(1) }
        scheduler.schedule(after: 220) { _ = observer.receive(2) }
        scheduler.schedule(after: 230) { _ = observer.receive(3) }
        scheduler.schedule(after: 240) { _ = observer.receive(4) }
        scheduler.schedule(after: 250) { _ = observer.receive(5) }
        scheduler.schedule(after: 260) { _ = observer.receive(completion: .finished) }

        var options = TestableSubscriberOptions.default
        options.subsequentDemand = Subscribers.Demand.unlimited
        options.negativeBalanceHandler = {}

        let subscriber = scheduler.createTestableSubscriber(Int.self, Never.self, options: options)
        producer.subscribe(subscriber)
        scheduler.resume()

        let expected: TestSequence<Int, Never> = [
          (0, .subscription),
          (210, .input(1)),
          (220, .input(2)),
          (230, .input(3)),
          (240, .input(4)),
          (250, .input(5)),
          (260, .completion(.finished)),
        ]

        expect(subscriber.recordedOutput).to(equal(expected))
      }

      it("should send errors") {
        var observer: Producer<Int, TestError>.Subscriber!
        let producer = Producer<Int, TestError> { o in
          observer = o
        }

        scheduler.schedule(after: 210) { _ = observer.receive(1) }
        scheduler.schedule(after: 220) { _ = observer.receive(completion: .failure(.generic)) }

        var options = TestableSubscriberOptions.default
        options.subsequentDemand = Subscribers.Demand.unlimited
        options.negativeBalanceHandler = {}

        let subscriber = scheduler.createTestableSubscriber(Int.self, TestError.self, options: options)
        producer.subscribe(subscriber)
        scheduler.resume()

        let expected: TestSequence<Int, TestError> = [
          (0, .subscription),
          (210, .input(1)),
          (220, .completion(.failure(.generic))),
        ]

        expect(subscriber.recordedOutput).to(equal(expected))
      }
    }
  }

}
