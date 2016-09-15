//
//  AddAccountViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

class AddAccountViewModel {

  enum AddAccountError: Error {
    case IncorrectCredentials
  }

  let api: EmonCMSAPI

  var url = Variable<String>("")
  var apikey = Variable<String>("")

  init(api: EmonCMSAPI) {
    self.api = api
  }

  func canSave() -> Observable<Bool> {
    return Observable
      .combineLatest(self.url.asObservable(), self.apikey.asObservable()) { url, apikey in
        return !url.isEmpty && !apikey.isEmpty
    }
  }

  func validate(account: Account) -> Observable<Account> {
    return self.api.feedList(account)
      .catchError { (_) -> Observable<[Feed]> in
        // TODO: Probably check what the actual error is here. If it's a network error, we could have a different error thrown
        throw AddAccountError.IncorrectCredentials
      }
      .map { _ in
        return account
    }
  }

}
