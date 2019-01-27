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

class FeedListHelperTests: EmonCMSTestCase {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedListHelper!

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
      viewModel = FeedListHelper(realmController: realmController, account: accountController, api: api)
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

      it("should refresh when asked to") {
        let refreshObserver = scheduler.createObserver(Bool.self)
        viewModel.isRefreshing
          .drive(refreshObserver)
          .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(10, ()), .next(20, ())])
          .bind(to: viewModel.refresh)
          .disposed(by: disposeBag)

        scheduler.start()

        expect(refreshObserver.events).toEventually(equal([
          .next(0, false),
          .next(10, true),
          .next(20, false),
          .next(20, true),
          .next(20, false),
          ]))
      }
    }

  }

}
