//
//  InputListViewModelTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 120/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Quick
import Nimble
import EntwineTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class InputListViewModelTests: EmonCMSTestCase {

  override func spec() {

    var scheduler: TestScheduler!
    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: InputListViewModel!

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
      viewModel = InputListViewModel(realmController: realmController,account: accountController, api: api)
    }

    describe("inputHandling") {
      it("should list all inputs") {
        let sut = viewModel.$inputs

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

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        expect(results.recordedOutput.count).toEventually(equal(3))
        let lastEventInputsSignal = results.recordedOutput.suffix(1).first!.1
        let lastEventInputs = lastEventInputsSignal.value ?? []
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
