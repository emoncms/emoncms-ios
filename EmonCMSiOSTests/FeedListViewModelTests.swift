//
//  FeedListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class FeedListViewModelTests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedListViewModel!

    beforeEach {
      disposeBag = DisposeBag()
      scheduler = TestScheduler(initialClock: 0)

      let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
      accountController = AccountController(uuid: "testaccount", credentials: credentials)
      realm = accountController.createRealm()
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = FeedListViewModel(account: accountController, api: api)
    }

    describe("feedHandling") {
      it("should list all feeds") {
        let feedsObserver = scheduler.createObserver([FeedListViewModel.Section].self)
        viewModel.feeds
          .drive(feedsObserver)
          .disposed(by: disposeBag)

        let count = 10
        try! realm.write {
          for i in 0..<count {
            let feed = Feed()
            feed.id = "\(i)"
            feed.name = "Feed \(i)"
            feed.tag = "Tag \(i%2)"
            realm.add(feed)
          }
        }

        scheduler.start()

        expect(feedsObserver.events.count).toEventually(equal(2))

        let lastEventFeeds = feedsObserver.events.last!.value.element!
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
        let feedsObserver = scheduler.createObserver([FeedListViewModel.Section].self)
        viewModel.feeds
          .drive(feedsObserver)
          .disposed(by: disposeBag)

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

        scheduler.start()

        expect(feedsObserver.events.count).toEventually(equal(2))
        viewModel.searchTerm.accept("Feed 5")
        expect(feedsObserver.events.count).toEventually(equal(3))

        let lastEventFeeds = feedsObserver.events.last!.value.element!
        expect(lastEventFeeds.count).to(equal(1))
        guard lastEventFeeds.count == 1 else { return }

        let tag = lastEventFeeds[0]
        expect(tag.items.count).to(equal(1))
        if let feed = tag.items.first {
          expect(feed.name).to(equal("Feed 5"))
        }
      }
    }

  }

}
