//
//  FeedListHelperTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 19/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class FeedListHelperTests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedListHelper!

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
      viewModel = FeedListHelper(account: accountController, api: api)
    }

    describe("feedHandling") {
      it("should list all feeds") {
        let feedsObserver = scheduler.createObserver([FeedListHelper.FeedListItem].self)
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

        let lastEventFeeds = feedsObserver.events.last!.value.element!
        expect(lastEventFeeds.count).to(equal(10))

        for (i, feed) in lastEventFeeds.enumerated() {
          expect(feed.feedId).to(equal("\(i)"))
          expect(feed.name).to(equal("Feed \(i)"))
        }
      }
    }

  }

}
