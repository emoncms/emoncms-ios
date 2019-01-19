//
//  FeedChartViewModelTests.swift
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

class FeedChartViewModelTests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: FeedChartViewModel!

    beforeEach {
      disposeBag = DisposeBag()
      scheduler = TestScheduler(initialClock: 0)

      let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
      accountController = AccountController(uuid: "testaccount-\(type(of: self))", credentials: credentials)
      realm = accountController.createRealm()
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = FeedChartViewModel(account: accountController, api: api, feedId: "1")
    }

    describe("dataHandling") {
      it("should fetch feed data") {
        let dataPointsObserver = scheduler.createObserver([DataPoint].self)
        viewModel.dataPoints
          .drive(dataPointsObserver)
          .disposed(by: disposeBag)

        viewModel.active.accept(true)

        scheduler.start()

        expect(dataPointsObserver.events.count).toEventually(equal(1))
      }

      it("should refresh when asked to") {
        let dataPointsObserver = scheduler.createObserver([DataPoint].self)
        viewModel.dataPoints
          .drive(dataPointsObserver)
          .disposed(by: disposeBag)

        let refreshObserver = scheduler.createObserver(Bool.self)
        viewModel.isRefreshing
          .drive(refreshObserver)
          .disposed(by: disposeBag)

        viewModel.active.accept(true)

        scheduler.createColdObservable([.next(10, ()), .next(20, ())])
          .bind(to: viewModel.refresh)
          .disposed(by: disposeBag)

        scheduler.start()

        expect(dataPointsObserver.events.count).toEventually(equal(3))
        expect(refreshObserver.events).to(equal([
          .next(0, false),
          .next(0, true),
          .next(0, false),
          .next(10, true),
          .next(10, false),
          .next(20, true),
          .next(20, false),
        ]))
      }
    }

  }

}
