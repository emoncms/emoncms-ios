//
//  DashboardListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class DashboardListViewModelTests: EmonCMSTestCase {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: DashboardListViewModel!

    beforeEach {
      disposeBag = DisposeBag()
      scheduler = TestScheduler(initialClock: 0)

      let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
      accountController = AccountController(uuid: "testaccount-\(type(of: self))", dataDirectory: self.dataDirectory, credentials: credentials)
      realm = accountController.createRealm()
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = DashboardListViewModel(account: accountController, api: api)
    }

    describe("dashboardHandling") {
      it("should list all dashboards") {
        let dashboardsObserver = scheduler.createObserver([DashboardListViewModel.ListItem].self)
        viewModel.dashboards
          .drive(dashboardsObserver)
          .disposed(by: disposeBag)

        let count = 10
        try! realm.write {
          for i in 0..<count {
            let dashboard = Dashboard()
            dashboard.id = "\(i)"
            dashboard.alias = "\(i)"
            dashboard.name = "Dashboard \(i)"
            dashboard.desc = "Description \(i)"
            realm.add(dashboard)
          }
        }

        scheduler.start()

        expect(dashboardsObserver.events.count).toEventually(equal(2))
        let lastEventDashboards = dashboardsObserver.events.last!.value.element!
        expect(lastEventDashboards.count).to(equal(10))
        for (i, dashboard) in lastEventDashboards.enumerated() {
          expect(dashboard.dashboardId).to(equal("\(i)"))
          expect(dashboard.name).to(equal("Dashboard \(i)"))
          expect(dashboard.desc).to(equal("Description \(i)"))
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
