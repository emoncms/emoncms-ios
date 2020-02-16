//
//  FeedChartViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 19/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Nimble
import Quick
import Realm
import RealmSwift

class FeedChartViewModelTests: EmonCMSTestCase {
  override func spec() {
    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedChartViewModel!

    beforeEach {
      scheduler = TestScheduler(initialClock: 0)

      realmController = RealmController(dataDirectory: self.dataDirectory)
      let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
      accountController = AccountController(uuid: "testaccount-\(type(of: self))", credentials: credentials)
      realm = realmController.createAccountRealm(forAccountId: accountController.uuid)
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = FeedChartViewModel(account: accountController, api: api, feedId: "1")
    }

    describe("dataHandling") {
      it("should fetch feed data") {
        let subscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, Never.self)
        viewModel.$dataPoints
          .subscribe(subscriber)

        viewModel.active = true

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        scheduler.resume()

        expect(subscriber.recordedOutput.count).toEventually(equal(3))
      }

      it("should refresh when asked to") {
        let dataPointsSubscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, Never.self)
        viewModel.$dataPoints
          .subscribe(dataPointsSubscriber)

        let refreshSubscriber = scheduler.createTestableSubscriber(Bool.self, Never.self)
        viewModel.isRefreshing
          .subscribe(refreshSubscriber)

        viewModel.active = true

        scheduler.schedule(after: 10) { viewModel.refresh.send(()) }
        scheduler.schedule(after: 20) { viewModel.refresh.send(()) }
        scheduler.resume()

        expect(dataPointsSubscriber.recordedOutput.count).toEventually(equal(5))
        expect(refreshSubscriber.recordedOutput).to(equal([
          (0, .subscription),
          (0, .input(true)),
          (0, .input(false)),
          (10, .input(true)),
          (10, .input(false)),
          (20, .input(true)),
          (20, .input(false))
        ]))
      }
    }
  }
}
