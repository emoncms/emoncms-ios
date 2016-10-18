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

  let url = Variable<String>("")
  let apikey = Variable<String>("")

  init(api: EmonCMSAPI) {
    self.api = api
  }

  func canSave() -> Observable<Bool> {
    return Observable
      .combineLatest(self.url.asObservable(), self.apikey.asObservable()) { url, apikey in
        return !url.isEmpty && !apikey.isEmpty
      }
      .distinctUntilChanged()
  }

  func validate() -> Observable<Account> {
    let account = Account(uuid: UUID(), url: self.url.value, apikey: self.apikey.value)
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
