//
//  AccountViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 29/04/2022.
//  Copyright © 2022 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Nimble
import Quick
import Realm
import RealmSwift

class AccountViewModelTests: EmonCMSTestCase {
  override func spec() {
    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: AccountViewModel!

    beforeEach {
      scheduler = TestScheduler(initialClock: 0)

      realmController = RealmController(dataDirectory: self.dataDirectory)
      let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
      accountController = AccountController(uuid: "testaccount-\(type(of: self))", credentials: credentials)

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = AccountViewModel(realmController: realmController, account: accountController, api: api)
    }

    describe("version") {
      it("should fetch version") {
        let sut = viewModel.checkEmoncmsServerVersion()

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let output = results.recordedOutput
        expect(output.count).toEventually(equal(2))
        expect(output[1].1.completion).toNot(beNil())
        expect(output[1].1.completion!).to(equal(.finished))
      }

      it("should fetch version and fail for old version") {
        requestProvider.nextResponseOverride = "1.0.0"

        let sut = viewModel.checkEmoncmsServerVersion()

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let output = results.recordedOutput
        expect(output.count).toEventually(equal(2))
        expect(output[1].1.completion).toNot(beNil())
        expect(output[1].1.completion!)
          .to(equal(.failure(.versionNotSupported(SemanticVersion(major: 1, minor: 0, patch: 0)))))
      }
    }
  }
}
