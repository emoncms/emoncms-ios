//
//  InputListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 120/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class InputListViewModelTests: EmonCMSTestCase {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: InputListViewModel!

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
      viewModel = InputListViewModel(account: accountController, api: api)
    }

    describe("inputHandling") {
      it("should list all inputs") {
        let inputsObserver = scheduler.createObserver([InputListViewModel.Section].self)
        viewModel.inputs
          .drive(inputsObserver)
          .disposed(by: disposeBag)

        let count = 10
        try! realm.write {
          for i in 0..<count {
            let input = Input()
            input.id = "\(i)"
            input.nodeid = "\(i%2)"
            input.name = "Input \(i)"
            input.desc = "Description \(i)"
            realm.add(input)
          }
        }

        scheduler.start()

        expect(inputsObserver.events.count).toEventually(equal(2))

        let lastEventInputs = inputsObserver.events.last!.value.element!
        expect(lastEventInputs.count).to(equal(2))
        guard lastEventInputs.count == 2 else { return }

        let node0 = lastEventInputs[0]
        expect(node0.model).to(equal("0"))
        for (i, input) in node0.items.enumerated() {
          expect(input.inputId).to(equal("\(i * 2)"))
          expect(input.name).to(equal("Input \(i * 2)"))
          expect(input.desc).to(equal("Description \(i * 2)"))
        }

        let node1 = lastEventInputs[1]
        expect(node1.model).to(equal("1"))
        for (i, input) in node1.items.enumerated() {
          expect(input.inputId).to(equal("\(i * 2 + 1)"))
          expect(input.name).to(equal("Input \(i * 2 + 1)"))
          expect(input.desc).to(equal("Description \(i * 2 + 1)"))
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
