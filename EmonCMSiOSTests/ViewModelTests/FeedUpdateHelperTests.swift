//
//  FeedUpdateHelperTests.swift
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

class FeedUpdateHelperTests: EmonCMSTestCase {

  override func spec() {

    var disposeBag: DisposeBag!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedUpdateHelper!

    beforeEach {
      disposeBag = DisposeBag()

      realmController = RealmController(dataDirectory: self.dataDirectory)
      let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
      accountController = AccountController(uuid: "testaccount-\(type(of: self))", credentials: credentials)
      realm = realmController.createAccountRealm(forAccountId: accountController.uuid)
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = FeedUpdateHelper(realmController: realmController, account: accountController, api: api)
    }

    describe("feedHandling") {
      it("should update feeds") {
        waitUntil { done in
          viewModel.updateFeeds()
            .subscribe(
              onError: {
                fail($0.localizedDescription)
                done()
              },
              onCompleted: {
                done()
              })
            .disposed(by: disposeBag)
        }

        let results = realm.objects(Feed.self)
        expect(results.count).toEventually(equal(2))
      }

      it("should delete missing feeds") {
        let newFeedId = "differentId"

        try! realm.write {
          let feed = Feed()
          feed.id = newFeedId
          realm.add(feed)
        }

        waitUntil { done in
          viewModel.updateFeeds()
            .subscribe(
              onError: {
                fail($0.localizedDescription)
                done()
            },
              onCompleted: {
                done()
            })
            .disposed(by: disposeBag)
        }

        let result = realm.object(ofType: Feed.self, forPrimaryKey: newFeedId)
        expect(result).toEventually(beNil(), timeout: 1)
      }
    }

    describe("todayWidgetFeeds") {
      it("should delete ones for old feeds") {
        let newFeedId = "differentId"

        try! realm.write {
          let feed = Feed()
          feed.id = newFeedId
          realm.add(feed)
        }

        let mainRealm = realmController.createMainRealm()
        try! mainRealm.write {
          let todayWidgetFeed = TodayWidgetFeed()
          todayWidgetFeed.accountId = accountController.uuid
          todayWidgetFeed.feedId = newFeedId
          mainRealm.add(todayWidgetFeed)
        }

        waitUntil { done in
          viewModel.updateFeeds()
            .subscribe(
              onError: {
                fail($0.localizedDescription)
                done()
            },
              onCompleted: {
                done()
            })
            .disposed(by: disposeBag)
        }

        let results = realm.objects(TodayWidgetFeed.self)
        expect(results.count).toEventually(equal(0))
      }
    }

  }

}
