//
//  SettingsViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import RealmSwift

final class SettingsViewModel {
  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm

  private var cancellables = Set<AnyCancellable>()

  // Inputs
  @Published var active = false

  // Outputs
  let feedList: FeedListHelper

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)

    self.feedList = FeedListHelper(realmController: realmController, account: account, api: api)

    $active
      .removeDuplicates()
      .filter { $0 == true }
      .becomeVoid()
      .subscribe(self.feedList.refresh)
      .store(in: &self.cancellables)
  }

  func todayWidgetFeedsListViewModel() -> TodayWidgetFeedsListViewModel {
    return TodayWidgetFeedsListViewModel(realmController: self.realmController, accountController: self.account, api: self.api)
  }
}
