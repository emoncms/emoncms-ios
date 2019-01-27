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

class FeedListViewModelTests: EmonCMSTestCase {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedListViewModel!

    beforeEach {
      disposeBag = DisposeBag()
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

      it("should refresh when asked to") {
        let refreshObserver = scheduler.createObserver(Bool.self)
        viewModel.isRefreshing
          .drive(refreshObserver)
          .disposed(by: disposeBag)

        viewModel.active.accept(true)

        scheduler.createColdObservable([.next(10, ()), .next(20, ())])
          .bind(to: viewModel.refresh)
          .disposed(by: disposeBag)

        scheduler.start()

        expect(refreshObserver.events).toEventually(equal([
          .next(0, false),
          .next(0, true),
          .next(10, false),
          .next(10, true),
          .next(20, false),
          .next(20, true),
          .next(20, false),
          ]))
      }
    }

  }

}
