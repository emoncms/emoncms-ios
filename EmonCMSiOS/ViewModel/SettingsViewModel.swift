//
//  SettingsViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class SettingsViewModel {

  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)

  // Outputs
  let feedList: FeedListHelper

  init(account: AccountController, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()

    self.feedList = FeedListHelper(account: account, api: api)

    self.active.asObservable()
      .distinctUntilChanged()
      .filter { $0 == true }
      .becomeVoid()
      .subscribe(self.feedList.refresh)
      .disposed(by: self.disposeBag)
  }

}
