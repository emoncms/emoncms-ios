//
//  AccountListViewModelTests.swift
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

class AccountListViewModelTests: EmonCMSTestCase {

  override func spec() {

    var realmController: RealmController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!

    beforeEach {
      realmController = RealmController(dataDirectory: self.dataDirectory)
      realm = realmController.createMainRealm()
      try! realm.write {
        realm.deleteAll()
      }
      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
    }

    describe("migratingOldAccount") {
      it("should migrate the old account") {
        let uuid = UUID().uuidString
        let url = "url"
        UserDefaults.standard.set(uuid, forKey: SharedConstants.UserDefaultsKeys.accountUUID.rawValue)
        UserDefaults.standard.set(url, forKey: SharedConstants.UserDefaultsKeys.accountURL.rawValue)

        _ = AccountListViewModel(realmController: realmController, api: api)
        let accountQuery = realm.objects(Account.self)
        let firstAccount = accountQuery.first
        expect(firstAccount).toNot(beNil())
        expect(firstAccount?.uuid).to(equal(uuid))
        expect(firstAccount?.url).to(equal(url))
        expect(firstAccount?.name).to(equal(url))
      }
    }

    describe("accountHandling") {

      var scheduler: TestScheduler!
      var viewModel: AccountListViewModel!

      beforeEach {
        scheduler = TestScheduler(initialClock: 0)
        viewModel = AccountListViewModel(realmController: realmController, api: api)
      }

      it("should list all accounts") {
        let sut = viewModel.$accounts

        let count = 10
        try! realm.write {
          for i in 0..<count {
            let account = Account()
            account.name = "Account \(i)"
            account.url = "URL \(i)"
            realm.add(account)
          }
        }

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        expect(results.recordedOutput.count).toEventually(equal(3))
        let lastEventAccountsSignal = results.recordedOutput.suffix(1).first!.1
        let lastEventAccounts = lastEventAccountsSignal.value ?? []
        expect(lastEventAccounts.count).to(equal(10))
        for (i, account) in lastEventAccounts.enumerated() {
          expect(account.name).to(equal("Account \(i)"))
          expect(account.url).to(equal("URL \(i)"))
        }
      }

      it("should delete accounts properly") {
        var uuid: String = ""
        try! realm.write {
          let account = Account()
          account.name = "Account"
          account.url = "URL"
          uuid = account.uuid
          realm.add(account)
        }

        let accountQuery1 = realm.objects(Account.self)
        expect(accountQuery1.count).to(equal(1))

        waitUntil { (done) in
          _ = viewModel.deleteAccount(withId: uuid)
            .sink(
              receiveCompletion: { completion in
                switch completion {
                case .finished:
                  let accountQuery2 = realm.objects(Account.self)
                  expect(accountQuery2.count).to(equal(0))
                case .failure:
                  fail("Failure is not an option")
                }
                done()
            },
              receiveValue: { _ in }
          )
        }
      }

      it("should delete today widget feeds for deleted accounts") {
        var uuid: String = ""
        try! realm.write {
          let account = Account()
          account.name = "Account"
          account.url = "URL"
          uuid = account.uuid
          realm.add(account)

          let todayWidgetFeed = TodayWidgetFeed()
          todayWidgetFeed.accountId = account.uuid
          todayWidgetFeed.feedId = "feedId"
          realm.add(todayWidgetFeed)
        }

        waitUntil { (done) in
          _ = viewModel.deleteAccount(withId: uuid)
            .sink(
              receiveCompletion: { completion in
                switch completion {
                case .finished:
                  let query = realm.objects(TodayWidgetFeed.self)
                  expect(query.count).to(equal(0))
                case .failure:
                  fail("Failure is not an option")
                }
                done()
            },
              receiveValue: { _ in }
          )
        }
      }
    }

  }

}
