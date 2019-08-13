//
//  DashboardListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import EntwineTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class DashboardListViewModelTests: EmonCMSTestCase {

  override func spec() {

    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: DashboardListViewModel!

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
      viewModel = DashboardListViewModel(realmController: realmController, account: accountController, api: api)
    }

    describe("dashboardHandling") {
      it("should list all dashboards") {
        let sut = viewModel.$dashboards

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

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        expect(results.recordedOutput.count).toEventually(equal(3))
        let lastEventDashboardsSignal = results.recordedOutput.suffix(1).first!.1
        let lastEventDashboards: [DashboardListViewModel.ListItem]
        switch lastEventDashboardsSignal {
        case .input(let v):
          lastEventDashboards = v
        default:
          lastEventDashboards = []
        }
        expect(lastEventDashboards.count).to(equal(10))
        for (i, dashboard) in lastEventDashboards.enumerated() {
          expect(dashboard.dashboardId).to(equal("\(i)"))
          expect(dashboard.name).to(equal("Dashboard \(i)"))
          expect(dashboard.desc).to(equal("Description \(i)"))
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
          (10, .input(false)),
          (20, .input(true)),
          (20, .input(false)),
        ]))
      }
    }

  }

}
