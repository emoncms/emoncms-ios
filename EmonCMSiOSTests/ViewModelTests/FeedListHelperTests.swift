//
//  FeedListHelperTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 19/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Quick
import Nimble
import EntwineTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class FeedListHelperTests: EmonCMSTestCase {

  override func spec() {

    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedListHelper!

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
      viewModel = FeedListHelper(realmController: realmController, account: accountController, api: api)
    }

    describe("feedHandling") {
      it("should list all feeds") {
        let sut = viewModel.$feeds

        let count = 10
        try! realm.write {
          for i in 0..<count {
            let feed = Feed()
            feed.id = "\(i)"
            feed.name = "Feed \(i)"
            feed.tag = "Tag"
            realm.add(feed)
          }
        }

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        expect(results.recordedOutput.count).toEventually(equal(3))
        let lastEventFeedsSignal = results.recordedOutput.suffix(1).first!.1
        let lastEventFeeds: [FeedListHelper.FeedListItem]
        switch lastEventFeedsSignal {
        case .input(let v):
          lastEventFeeds = v
        default:
          lastEventFeeds = []
        }
        expect(lastEventFeeds.count).to(equal(10))
        for (i, feed) in lastEventFeeds.enumerated() {
          expect(feed.feedId).to(equal("\(i)"))
          expect(feed.name).to(equal("Feed \(i)"))
        }
      }

      it("should refresh when asked to") {
        let subscriber = scheduler.createTestableSubscriber(Bool.self, Never.self)

        viewModel.isRefreshing
          .subscribe(subscriber)

        scheduler.schedule(after: 10) { viewModel.refresh.send(()) }
        scheduler.schedule(after: 20) { viewModel.refresh.send(()) }
        scheduler.resume()

        expect(subscriber.recordedOutput).toEventually(equal([
          (0, .subscription),
          (10, .input(true)),
          (20, .input(false)),
          (20, .input(true)),
          (20, .input(false)),
        ]))
      }
    }

  }

}
