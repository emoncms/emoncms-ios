//
//  EmonCMSAccount.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import Locksmith

struct Account {

  enum AccountError: Error {
    case InvalidURL
    case IncorrectCredentials
  }

  let url: String
  let apikey: String

  init(url: String, apikey: String) {
    self.url = url
    self.apikey = apikey
  }

  func validate() -> Observable<Void> {
    guard URLComponents(string: url) != nil else {
      return Observable.error(AccountError.InvalidURL)
    }

    let api = EmonCMSAPI(account: self)
    return api.feedList()
      .catchError { (_) -> Observable<[Feed]> in
        // TODO: Probably check what the actual error is here. If it's a network error, we could have a different error thrown
        throw AccountError.IncorrectCredentials
      }
      .map { _ in
        return
      }
      .ignoreElements()
      .concat(Observable.empty())
  }

}
