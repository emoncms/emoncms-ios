//
//  DashboardUpdateHelperTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Quick
import Nimble
import EntwineTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class DashboardUpdateHelperTests: EmonCMSTestCase {

  override func spec() {

    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: DashboardUpdateHelper!

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
      viewModel = DashboardUpdateHelper(realmController: realmController, account: accountController, api: api)
    }

    describe("dashboardHandling") {
      it("should update dashboards") {
        waitUntil { done in
          _ = viewModel.updateDashboards()
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
        }

        let results = realm.objects(Dashboard.self)
        expect(results.count).toEventually(equal(2))
      }

      it("should delete missing dashboards") {
        let newDashboardId = "differentId"

        try! realm.write {
          let dashboard = Dashboard()
          dashboard.id = newDashboardId
          realm.add(dashboard)
        }

        waitUntil { done in
          _ = viewModel.updateDashboards()
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
        }

        expect { realm.object(ofType: Dashboard.self, forPrimaryKey: newDashboardId) }
          .toEventually(beNil())
      }
    }

  }

}
