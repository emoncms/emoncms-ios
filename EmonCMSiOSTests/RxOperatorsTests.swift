//
//  RxOperatorsTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
@testable import EmonCMSiOS

class RxOperatorsTests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    
    beforeEach {
      disposeBag = DisposeBag()
      scheduler = TestScheduler(initialClock: 0)
    }

    describe("becomeVoid") {
      it("should work") {
        // For some reason we can't use Void.self here - the type system just breaks when doing the matching.
        let observer = scheduler.createObserver(Bool.self)

        scheduler.createColdObservable([.next(10, 1), .next(20, 2), .next(30, 3)])
          .becomeVoid()
          .map {
            return true
          }
          .bind(to: observer)
          .disposed(by: disposeBag)

        scheduler.start()

        let expected: [Recorded<Event<Bool>>] = [
          .next(10, true),
          .next(20, true),
          .next(30, true),
        ]

        expect(observer.events).to(equal(expected))
      }
    }

    describe("log") {
      it("should work") {
        var values = [String]()
        let logger = { (string: String) in
          values.append(string)
        }

        let observer = scheduler.createObserver(Int.self)

        scheduler.createColdObservable([.next(10, 1), .next(20, 2), .next(20, 3), .completed(30)])
          .log(logger)
          .bind(to: observer)
          .disposed(by: disposeBag)

        scheduler.start()

        let expected = [
          "RxTest.ColdObservable<Swift.Int>: onSubscribe",
          "RxTest.ColdObservable<Swift.Int>: onSubscribed",
          "RxTest.ColdObservable<Swift.Int>: onNext <1>",
          "RxTest.ColdObservable<Swift.Int>: onNext <2>",
          "RxTest.ColdObservable<Swift.Int>: onNext <3>",
          "RxTest.ColdObservable<Swift.Int>: onCompleted",
          "RxTest.ColdObservable<Swift.Int>: onDispose",
        ]

        expect(values).to(equal(expected))
      }
    }

  }

}
