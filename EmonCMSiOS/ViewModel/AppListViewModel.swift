//
//  AppsListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

class AppListViewModel {

  private let account: Account
  private let api: EmonCMSAPI

  struct ListItem {
    let name: String
    let storyboardIdentifier: String
    let viewModelGenerator: () -> AppViewModel
  }

  var apps: Observable<[ListItem]> {
    return Observable.just([
      ListItem(name: "My Electric", storyboardIdentifier: "myElectric") {
        return MyElectricAppViewModel(account: self.account, api: self.api)
      }
    ])
  }

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
  }

}
