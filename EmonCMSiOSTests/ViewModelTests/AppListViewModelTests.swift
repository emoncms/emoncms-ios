//
//  AppListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Quick
import Nimble
import EntwineTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class AppListViewModelTests: EmonCMSTestCase {

  override func spec() {

    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: AppListViewModel!

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
      viewModel = AppListViewModel(realmController: realmController,account: accountController, api: api)
    }

    describe("appHandling") {
      it("should list all apps") {
        let sut = viewModel.$apps

        let count = 10
        try! realm.write {
          for i in 0..<count {
            let app = AppData()
            app.name = "App \(i)"
            let allAppCategories = AppCategory.allCases
            app.appCategory = allAppCategories[i % allAppCategories.count]
            realm.add(app)
          }
        }

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        expect(results.recordedOutput.count).toEventually(equal(3))
        let lastEventAppsSignal = results.recordedOutput.suffix(1).first!.1
        let lastEventApps = lastEventAppsSignal.value ?? []
        expect(lastEventApps.count).to(equal(10))
        for (i, app) in lastEventApps.enumerated() {
          expect(app.name).to(equal("App \(i)"))
        }
      }

      it("should delete apps properly") {
        var uuid: String = ""
        try! realm.write {
          let app = AppData()
          app.name = "TestApp"
          app.appCategory = .myElectric
          uuid = app.uuid
          realm.add(app)
        }

        let appQuery1 = realm.objects(AppData.self)
        expect(appQuery1.count).to(equal(1))

        _ = viewModel.deleteApp(withId: uuid)
          .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
              let appQuery2 = realm.objects(AppData.self)
              expect(appQuery2.count).to(equal(0))
            case .failure:
              fail("Failure is not an option")
            }
          },
                receiveValue: { _ in }
        )
      }
    }

  }

}
