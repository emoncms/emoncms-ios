//
//  InputUpdateHelperTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Quick
import Nimble
import EntwineTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class InputUpdateHelperTests: EmonCMSTestCase {

  override func spec() {

    var realmController: RealmController!
    var accountController: AccountController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: InputUpdateHelper!

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
      viewModel = InputUpdateHelper(realmController: realmController, account: accountController, api: api)
    }

    describe("inputHandling") {
      it("should update inputs") {
        waitUntil { done in
          _ = viewModel.updateInputs()
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

        let results = realm.objects(Input.self)
        expect(results.count).toEventually(equal(2))
      }

      it("should delete missing inputs") {
        let newInputId = "differentId"

        try! realm.write {
          let input = Input()
          input.id = newInputId
          realm.add(input)
        }

        waitUntil { done in
          _ = viewModel.updateInputs()
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

        expect { realm.object(ofType: Input.self, forPrimaryKey: newInputId) }
          .toEventually(beNil())
      }
    }

  }

}
