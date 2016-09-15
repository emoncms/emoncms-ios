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

  let url: String
  let apikey: String

  init(url: String, apikey: String) {
    self.url = url
    self.apikey = apikey
  }

}
