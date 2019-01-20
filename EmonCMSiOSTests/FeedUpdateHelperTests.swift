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
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedUpdateHelper!

    beforeEach {
      disposeBag = DisposeBag()

      let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
      accountController = AccountController(uuid: "testaccount-\(type(of: self))", dataDirectory: self.dataDirectory, credentials: credentials)
      realm = accountController.createRealm()
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = FeedUpdateHelper(account: accountController, api: api)
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
    }

  }

}
