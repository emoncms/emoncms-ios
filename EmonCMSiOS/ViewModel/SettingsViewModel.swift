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
import WatchConnectivity

class SettingsViewModel {

  private let account: Account
  private let api: EmonCMSAPI
  private let watchController: WatchController
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs
  let active = Variable<Bool>(false)
  let watchFeed = Variable<FeedListHelper.FeedListItem?>(nil)

  // Outputs
  let feedList: FeedListHelper
  var showWatchSection: Bool {
    return self.watchController.isPaired && self.watchController.isWatchAppInstalled
  }

  init(account: Account, api: EmonCMSAPI, watchController: WatchController) {
    self.account = account
    self.api = api
    self.watchController = watchController
    self.realm = account.createRealm()

    self.feedList = FeedListHelper(account: account, api: api)

    self.active.asObservable()
      .distinctUntilChanged()
      .filter { $0 == true }
      .becomeVoid()
      .subscribe(self.feedList.refresh)
      .addDisposableTo(self.disposeBag)

    if let feedId = self.watchController.complicationFeedId.value {
      self.watchFeed.value = FeedListHelper.FeedListItem(feedId: feedId, name: "")
    }

    self.watchFeed
      .asDriver()
      .map { $0?.feedId }
      .drive(self.watchController.complicationFeedId)
      .addDisposableTo(self.disposeBag)
  }

}
