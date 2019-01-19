//
//  AppListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class AppListViewModelTests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: AppListViewModel!

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
      viewModel = AppListViewModel(account: accountController, api: api)
    }

    describe("appHandling") {
      it("should list all apps") {
        let appsObserver = scheduler.createObserver([AppListViewModel.ListItem].self)
        viewModel.apps
          .drive(appsObserver)
          .disposed(by: disposeBag)

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

        scheduler.start()

        expect(appsObserver.events.count).toEventually(equal(2))
        let lastEventApps = appsObserver.events.last!.value.element!
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

        viewModel.deleteApp(withId: uuid)
          .subscribe(
            onError: { error in
              fail(error.localizedDescription)
          },
            onCompleted: {
              let appQuery2 = realm.objects(AppData.self)
              expect(appQuery2.count).to(equal(0))
          })
          .disposed(by: disposeBag)
      }
    }

  }

}
