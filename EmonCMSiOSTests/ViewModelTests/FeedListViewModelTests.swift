//
//  FeedListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Nimble
import Quick
import Realm
import RealmSwift

class FeedListViewModelTests: EmonCMSTestCase {
  override func spec() {
    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedListViewModel!

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
      viewModel = FeedListViewModel(realmController: realmController, account: accountController, api: api)
    }

    describe("feedHandling") {
      it("should list all feeds") {
        let sut = viewModel.$feeds

        let count = 10
        try! realm.write {
          for i in 0 ..< count {
            let feed = Feed()
            feed.id = "\(i)"
            feed.name = "Feed \(i)"
            feed.tag = "Tag \(i % 2)"
            realm.add(feed)
          }
        }

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        expect(results.recordedOutput.count).toEventually(equal(3))
        let lastEventFeedsSignal = results.recordedOutput.suffix(1).first!.1
        let lastEventFeeds = lastEventFeedsSignal.value ?? []
        expect(lastEventFeeds.count).to(equal(2))
        guard lastEventFeeds.count == 2 else { return }

        let tag0 = lastEventFeeds[0]
        expect(tag0.model).to(equal("Tag 0"))
        for (i, feed) in tag0.items.enumerated() {
          expect(feed.feedId).to(equal("\(i * 2)"))
          expect(feed.name).to(equal("Feed \(i * 2)"))
        }

        let tag1 = lastEventFeeds[1]
        expect(tag1.model).to(equal("Tag 1"))
        for (i, feed) in tag1.items.enumerated() {
          expect(feed.feedId).to(equal("\(i * 2 + 1)"))
          expect(feed.name).to(equal("Feed \(i * 2 + 1)"))
        }
      }

      it("should list the right feeds when searching") {
        let sut = viewModel.$feeds

        let count = 10
        try! realm.write {
          for i in 0 ..< count {
            let feed = Feed()
            feed.id = "\(i)"
            feed.name = "Feed \(i)"
            feed.tag = "Tag"
            realm.add(feed)
          }
        }

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        scheduler.schedule(after: 350) { viewModel.searchTerm = "Feed 5" }
        scheduler.schedule(after: 400) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        expect(results.recordedOutput.count).toEventually(equal(4))
        let lastEventFeedsSignal = results.recordedOutput.suffix(1).first!.1
        let lastEventFeeds = lastEventFeedsSignal.value ?? []
        expect(lastEventFeeds.count).to(equal(1))
        guard lastEventFeeds.count == 1 else { return }

        let tag = lastEventFeeds[0]
        expect(tag.items.count).to(equal(1))
        if let feed = tag.items.first {
          expect(feed.name).to(equal("Feed 5"))
        }
      }

      it("should refresh when asked to") {
        let subscriber = scheduler.createTestableSubscriber(Bool.self, Never.self)

        viewModel.isRefreshing
          .subscribe(subscriber)

        viewModel.active = true

        scheduler.schedule(after: 10) { viewModel.refresh.send(()) }
        scheduler.schedule(after: 20) { viewModel.refresh.send(()) }
        scheduler.resume()

        expect(subscriber.recordedOutput).toEventually(equal([
          (0, .subscription),
          (0, .input(true)),
          (10, .input(false)),
          (10, .input(true)),
          (20, .input(false)),
          (20, .input(true)),
          (20, .input(false))
        ]))
      }
    }
  }
}
