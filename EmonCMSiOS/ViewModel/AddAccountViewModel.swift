//
//  AddAccountViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

final class AddAccountViewModel {

  enum AddAccountError: Error {
    case httpsRequired
    case networkFailed
    case invalidCredentials
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
      .catchError { error -> Observable<[Feed]> in
        let returnError: AddAccountError
        if let error = error as? EmonCMSAPI.EmonCMSAPIError {
          switch error {
          case .invalidCredentials:
            returnError = .invalidCredentials
          case .atsFailed:
            returnError = .httpsRequired
          default:
            returnError = .networkFailed
          }
        } else {
          returnError = .networkFailed
        }

        return Observable.error(returnError)
      }
      .map { _ in
        return account
    }
  }

}
