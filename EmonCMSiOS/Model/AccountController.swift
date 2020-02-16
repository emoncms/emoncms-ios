//
//  AccountController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

struct AccountCredentials {
  let url: String
  let apiKey: String
}

extension AccountCredentials: Equatable {
  static func == (lhs: AccountCredentials, rhs: AccountCredentials) -> Bool {
    return lhs.url == rhs.url &&
      lhs.apiKey == rhs.apiKey
  }
}

struct AccountController {
  let uuid: String
  let credentials: AccountCredentials
}

extension AccountController: Equatable {
  static func == (lhs: AccountController, rhs: AccountController) -> Bool {
    return lhs.uuid == rhs.uuid &&
      lhs.credentials == rhs.credentials
  }
}
