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
@testable import EmonCMSiOS

class AddAccountViewModelTests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var viewModel: AddAccountViewModel!

    beforeEach {
      disposeBag = DisposeBag()
      let requestProvider = MockHTTPRequestProvider()
      let api = EmonCMSAPI(requestProvider: requestProvider)
      viewModel = AddAccountViewModel(api: api)
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
        viewModel.url.accept("http://emoncms.org")
        viewModel.apikey.accept("abcdef")

        var result: Bool?
        viewModel.canSave()
          .subscribe(onNext: { result = $0 })
          .disposed(by: disposeBag)

        expect(result).to(equal(true))
      }
    }
    
  }

}
