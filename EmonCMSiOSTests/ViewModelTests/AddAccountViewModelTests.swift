//
//  AddAccountViewModelTests.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 18/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
import Realm
import RealmSwift
@testable import EmonCMSiOS

class AddAccountViewModelTests: EmonCMSTestCase {

  override func spec() {

    var disposeBag: DisposeBag!
    var realmController: RealmController!
    var realm: Realm!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var viewModel: AddAccountViewModel!

    beforeEach {
      disposeBag = DisposeBag()

      realmController = RealmController(dataDirectory: self.dataDirectory)
      realm = realmController.createRealm()
      try! realm.write {
        realm.deleteAll()
      }

      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = AddAccountViewModel(realmController: realmController, api: api)
    }

    describe("validate") {
      it("should error for invalid details") {
        let url = "https://test"
        let apiKey = "invalid"

        viewModel.name.accept("Test")
        viewModel.url.accept(url)
        viewModel.apikey.accept(apiKey)

        waitUntil { done in
          viewModel.validate()
            .subscribe(
              onError: { error in
                if let typedError = error as? AddAccountViewModel.AddAccountError {
                  expect(typedError).to(equal(AddAccountViewModel.AddAccountError.invalidCredentials))
                } else {
                  fail("Wrong error returned")
                }
                done()
              },
              onCompleted: {
                fail("Should have errored!")
                done()
              })
            .disposed(by: disposeBag)
        }
      }

      it("should succeed for valid details") {
        let url = "https://test"
        let apiKey = "ilikecats"

        viewModel.name.accept("Test")
        viewModel.url.accept(url)
        viewModel.apikey.accept(apiKey)

        waitUntil { done in
          viewModel.validate()
            .subscribe(
              onNext: { credentials in
                expect(credentials.url).to(equal(url))
                expect(credentials.apiKey).to(equal(apiKey))
            },
              onError: { error in
                fail(error.localizedDescription)
                done()
            },
              onCompleted: {
                done()
            })
            .disposed(by: disposeBag)
        }
      }
    }

    describe("canSave") {
      it("should be false for invalid input") {
        viewModel.url.accept("")
        viewModel.apikey.accept("")

        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(false))
      }

      it("should be true for valid input") {
        viewModel.name.accept("EmonCMS.org instance")
        viewModel.url.accept("http://emoncms.org")
        viewModel.apikey.accept("abcdef")

        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(true))
      }
    }

    describe("saveAccount") {
      it("should save an account successfully") {
        viewModel.saveAccount(withUrl: "http://emoncms.org", apiKey: "abcdef")
          .subscribe(
            onNext: {
              expect($0.count).toNot(equal(0))
            },
            onError: { error in
              fail(error.localizedDescription)
            },
            onCompleted: {
            })
          .disposed(by: disposeBag)
      }
    }
    
  }

}
