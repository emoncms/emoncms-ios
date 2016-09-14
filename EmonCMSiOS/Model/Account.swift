//
//  EmonCMSAccount.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Locksmith

struct Account {

  let url: String
  let apikey: String

  init(url: String, apikey: String) {
    self.url = url
    self.apikey = apikey
  }

  func validate(callback: @escaping (Bool) -> Void) {
    guard URLComponents(string: url) != nil else {
      callback(false)
      return
    }

    let api = EmonCMSAPI(account: self)
    api.feedList { result in
      switch result {
      case .Result(_):
        callback(true)
      case .Error:
        callback(false)
      }
    }
  }

}
