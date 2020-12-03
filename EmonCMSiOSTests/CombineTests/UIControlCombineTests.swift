//
//  UIControlCombineTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 03/12/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import EntwineTest
import Nimble
import Quick
import UIKit

class UIControlCombineTests: QuickSpec {
  override func spec() {
    var scheduler: TestScheduler!

    beforeEach {
      scheduler = TestScheduler(initialClock: 0)
    }

    describe("UIControl") {
      it("should track control correctly") {
        let button = UIButton()

        scheduler.schedule(after: 250) {
          button.sendActions(for: .touchUpInside)
        }

        scheduler.schedule(after: 260) {
          button.sendActions(for: .touchDown)
        }

        let sut = button.publisher(for: .touchUpInside)
        let results = scheduler.start { sut }

        let expected: TestSequence<UIControl, Never> = [
          (200, .subscription),
          (250, .input(button))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }
    }

    describe("UIGestureRecognizer") {
      it("should track recognizer correctly") {
        let recognizer = UIGestureRecognizer()

        let sut = recognizer.publisher()
        let results = scheduler.start { sut }

        let expected: TestSequence<UIGestureRecognizer, Never> = [
          (200, .subscription)
        ]

        expect(results.recordedOutput).to(equal(expected))
      }
    }
  }
}
