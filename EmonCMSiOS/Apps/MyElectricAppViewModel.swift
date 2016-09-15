//
//  MyElectricAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

class MyElectricAppViewModel: AppViewModel {

  private let account: Account
  private let api: EmonCMSAPI

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
  }

}
