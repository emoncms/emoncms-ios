//
//  AccountListViewModelTests.swift
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

      var disposeBag: DisposeBag!
      var scheduler: TestScheduler!
      var viewModel: AccountListViewModel!

      beforeEach {
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        viewModel = AccountListViewModel(realmController: realmController, api: api)
      }

      it("should list all accounts") {
        let accountsObserver = scheduler.createObserver([AccountListViewModel.ListItem].self)
        viewModel.accounts
          .drive(accountsObserver)
          .disposed(by: disposeBag)

        let count = 10
        try! realm.write {
          for i in 0..<count {
            let account = Account()
            account.name = "Account \(i)"
            account.url = "URL \(i)"
            realm.add(account)
          }
        }

        scheduler.start()

        expect(accountsObserver.events.count).toEventually(equal(2))
        let lastEventAccounts = accountsObserver.events.last!.value.element!
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

        viewModel.deleteAccount(withId: uuid)
          .subscribe(
            onError: { error in
              fail(error.localizedDescription)
          },
            onCompleted: {
              let accountQuery2 = realm.objects(Account.self)
              expect(accountQuery2.count).to(equal(0))
          })
          .disposed(by: disposeBag)
      }
    }

  }

}
