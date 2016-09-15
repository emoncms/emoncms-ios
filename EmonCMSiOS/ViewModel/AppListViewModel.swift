//
//  AppsListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

class AppListViewModel {

  private let account: Account
  private let api: EmonCMSAPI

  struct App {
    let name: String
    let storyboardIdentifier: String
    let viewModelGenerator: () -> AppViewModel
  }

  let apps: [App]

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    apps = [
      App(name: "My Electric", storyboardIdentifier: "myElectric") {
        return MyElectricAppViewModel(api: api)
      }
    ]
  }

}
