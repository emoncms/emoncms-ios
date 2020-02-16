//
//  AddAccountViewModelTests.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 18/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Nimble
import Quick
import Realm
import RealmSwift

class AddAccountViewModelTests: EmonCMSTestCase {
  override func spec() {
    var realmController: RealmController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: AddAccountViewModel!

    beforeEach {
      realmController = RealmController(dataDirectory: self.dataDirectory)
      realm = realmController.createMainRealm()
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = AddAccountViewModel(realmController: realmController, api: api)
    }

    describe("saveAccount") {
      it("should error for invalid details") {
        let url = "https://test"
        let apiKey = "invalid"

        viewModel.name = "Test"
        viewModel.url = url
        viewModel.apiKey = apiKey

        waitUntil { done in
          _ = viewModel.saveAccount()
            .sink(
              receiveCompletion: { completion in
                switch completion {
                case .finished:
                  fail("Should have errored!")
                case .failure(let error):
                  expect(error).to(equal(AddAccountViewModel.AddAccountError.invalidCredentials))
                }
                done()
              },
              receiveValue: { _ in })
        }
      }

      it("should succeed for valid details with username and password") {
        let url = "https://test"
        let username = "username"
        let password = "ilikecats"

        viewModel.name = "Test"
        viewModel.url = url
        viewModel.username = username
        viewModel.password = password

        waitUntil { done in
          _ = viewModel.saveAccount()
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
              receiveValue: { expect($0).toNot(equal("")) })
        }
      }

      it("should succeed for valid details with api key") {
        let url = "https://test"
        let apiKey = "ilikecats"

        viewModel.name = "Test"
        viewModel.url = url
        viewModel.apiKey = apiKey

        waitUntil { done in
          _ = viewModel.saveAccount()
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
              receiveValue: { expect($0).toNot(equal("")) })
        }
      }
    }

    describe("canSave") {
      it("should be false for invalid input") {
        var result: Bool?
        _ = viewModel.canSave()
          .sink(receiveValue: { result = $0 })

        expect(result).to(equal(false))
      }

      it("should be false when there's no name") {
        viewModel.url = "http://emoncms.org"
        viewModel.apiKey = "abcdef"

        var result: Bool?
        _ = viewModel.canSave()
          .sink(receiveValue: { result = $0 })

        expect(result).to(equal(false))
      }

      it("should be false when there's no credentials") {
        viewModel.name = "EmonCMS.org instance"
        viewModel.url = "http://emoncms.org"

        var result: Bool?
        _ = viewModel.canSave()
          .sink(receiveValue: { result = $0 })

        expect(result).to(equal(false))
      }

      it("should be true when there's username and password") {
        viewModel.name = "EmonCMS.org instance"
        viewModel.url = "http://emoncms.org"
        viewModel.username = "username"
        viewModel.password = "password"

        var result: Bool?
        _ = viewModel.canSave()
          .sink(receiveValue: { result = $0 })

        expect(result).to(equal(true))
      }

      it("should be true when there's api key") {
        viewModel.name = "EmonCMS.org instance"
        viewModel.url = "http://emoncms.org"
        viewModel.apiKey = "abcdef"

        var result: Bool?
        _ = viewModel.canSave()
          .sink(receiveValue: { result = $0 })

        expect(result).to(equal(true))
      }
    }
  }
}
