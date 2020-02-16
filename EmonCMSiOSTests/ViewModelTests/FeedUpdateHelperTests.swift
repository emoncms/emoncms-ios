//
//  FeedUpdateHelperTests.swift
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

class FeedUpdateHelperTests: EmonCMSTestCase {

  override func spec() {

    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedUpdateHelper!
    var cancellables: Set<AnyCancellable> = []

    beforeEach {
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
      cancellables.removeAll()
    }

    describe("feedHandling") {
      it("should update feeds") {
        waitUntil { done in
          let cancellable = viewModel.updateFeeds()
            .sink(
              receiveCompletion: { completion in
                switch completion {
                case .finished:
                  break
                case .failure(let error):
                  fail(error.localizedDescription)
                }
                done()
            },
              receiveValue: { _ in }
          )
          cancellables.insert(cancellable)
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
          let cancellable = viewModel.updateFeeds()
            .sink(
              receiveCompletion: { completion in
                switch completion {
                case .finished:
                  break
                case .failure(let error):
                  fail(error.localizedDescription)
                }
                done()
            },
              receiveValue: { _ in }
          )
          cancellables.insert(cancellable)
        }

        expect { realm.object(ofType: Feed.self, forPrimaryKey: newFeedId) }
          .toEventually(beNil())
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
          let cancellable = viewModel.updateFeeds()
            .sink(
              receiveCompletion: { completion in
                switch completion {
                case .finished:
                  break
                case .failure(let error):
                  fail(error.localizedDescription)
                }
                done()
            },
              receiveValue: { _ in }
          )
          cancellables.insert(cancellable)
        }

        let results = realm.objects(TodayWidgetFeed.self)
        expect(results.count).toEventually(equal(0))
      }
    }

  }

}
