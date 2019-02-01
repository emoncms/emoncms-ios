//
//  MySolarAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/12/2018.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class MySolarAppViewModel: AppViewModel {

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData

  // Inputs

  // Outputs
  private(set) var title: Driver<String>
  private(set) var isReady: Driver<Bool>

  var accessibilityIdentifier: String {
    return AccessibilityIdentifiers.Apps.MySolar
  }

  var pageViewControllerStoryboardIdentifiers: [String] {
    return ["mySolarPage1", "mySolarPage2"]
  }

  var pageViewModels: [AppPageViewModel] {
    return [self.page1ViewModel, self.page2ViewModel]
  }

  let page1ViewModel: MySolarAppPage1ViewModel
  let page2ViewModel: MySolarAppPage2ViewModel

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI, appDataId: String) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.appData = self.realm.object(ofType: AppData.self, forPrimaryKey: appDataId)!

    self.page1ViewModel = MySolarAppPage1ViewModel(realmController: realmController, account: account, api: api, appDataId: appDataId)
    self.page2ViewModel = MySolarAppPage2ViewModel(realmController: realmController, account: account, api: api, appDataId: appDataId)

    self.title = Driver.empty()
    self.isReady = Driver.empty()

    self.title = self.appData.rx
      .observe(String.self, "name")
      .map { $0 ?? "" }
      .asDriver(onErrorJustReturn: "")

    self.isReady = self.appData.rx.observe(String.self, #keyPath(AppData.name))
      .map {
        $0 != nil
      }
      .asDriver(onErrorJustReturn: false)
  }

  func configViewModel() -> AppConfigViewModel {
    return AppConfigViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: self.appData.uuid, appCategory: .mySolar)
  }

}
