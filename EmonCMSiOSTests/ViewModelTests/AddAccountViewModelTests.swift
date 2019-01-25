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

    describe("saveAccount") {
      it("should error for invalid details") {
        let url = "https://test"
        let apiKey = "invalid"

        viewModel.name.accept("Test")
        viewModel.url.accept(url)
        viewModel.apiKey.accept(apiKey)

        waitUntil { done in
          viewModel.saveAccount()
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

      it("should succeed for valid details with username and password") {
        let url = "https://test"
        let username = "username"
        let password = "ilikecats"

        viewModel.name.accept("Test")
        viewModel.url.accept(url)
        viewModel.username.accept(username)
        viewModel.password.accept(password)

        waitUntil { done in
          viewModel.saveAccount()
            .subscribe(
              onNext: {
                expect($0).toNot(equal(""))
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

      it("should succeed for valid details with api key") {
        let url = "https://test"
        let apiKey = "ilikecats"

        viewModel.name.accept("Test")
        viewModel.url.accept(url)
        viewModel.apiKey.accept(apiKey)

        waitUntil { done in
          viewModel.saveAccount()
            .subscribe(
              onNext: {
                expect($0).toNot(equal(""))
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
        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(false))
      }

      it("should be false when there's no name") {
        viewModel.url.accept("http://emoncms.org")
        viewModel.apiKey.accept("abcdef")

        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(false))
      }

      it("should be false when there's no credentials") {
        viewModel.name.accept("EmonCMS.org instance")
        viewModel.url.accept("http://emoncms.org")

        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(false))
      }

      it("should be true when there's username and password") {
        viewModel.name.accept("EmonCMS.org instance")
        viewModel.url.accept("http://emoncms.org")
        viewModel.username.accept("username")
        viewModel.password.accept("password")

        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(true))
      }

      it("should be true when there's api key") {
        viewModel.name.accept("EmonCMS.org instance")
        viewModel.url.accept("http://emoncms.org")
        viewModel.apiKey.accept("abcdef")

        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(true))
      }
    }
    
  }

}
