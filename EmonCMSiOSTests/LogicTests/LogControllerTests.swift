//
//  LogControllerTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Foundation
import Nimble
import Quick

class LogControllerTests: QuickSpec {
  override func spec() {
    beforeEach {}

    describe("logController") {
      it("should return log files") {
        let controller = LogController.shared

        let thingToLog = UUID().uuidString
        AppLog.info(thingToLog)

        waitUntil { done in
          controller.flushFile {
            done()
          }
        }

        let logFiles = controller.logFiles
        expect(logFiles.count).to(beGreaterThan(0))

        if
          let logFile = logFiles.first,
          let data = try? Data(contentsOf: logFile),
          let string = String(data: data, encoding: .utf8)
        {
          expect(string.contains(thingToLog)).to(equal(true))
        } else {
          fail("Failed to get log file data")
        }
      }
    }
  }
}
