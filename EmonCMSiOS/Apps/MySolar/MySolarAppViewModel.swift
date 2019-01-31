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
  let active = BehaviorRelay<Bool>(value: false)

  // Outputs
  private(set) var title: Driver<String>
  private(set) var isRefreshing: Driver<Bool>
  private(set) var isReady: Driver<Bool>
  private(set) var errors: Driver<AppError?>
  private(set) var bannerBarState: Driver<AppBannerBarState>

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
    self.errors = Driver.empty()
    self.bannerBarState = Driver.empty()

    self.title = self.appData.rx
      .observe(String.self, "name")
      .map { $0 ?? "" }
      .asDriver(onErrorJustReturn: "")

    self.isRefreshing = Observable.combineLatest(
      self.page1ViewModel.isRefreshing.asObservable(),
      self.page2ViewModel.isRefreshing.asObservable()) { $0 || $1 }
      .asDriver(onErrorJustReturn: false)

    self.isReady = self.appData.rx.observe(String.self, #keyPath(AppData.name))
      .map {
        $0 != nil
      }
      .asDriver(onErrorJustReturn: false)

    self.errors = Observable.merge(
      self.page1ViewModel.errors.asObservable(),
      self.page2ViewModel.errors.asObservable())
      .asDriver(onErrorJustReturn: nil)

    let errors = self.errors.asObservable()
    let loading = self.isRefreshing.asObservable()
    let updateTime = Observable.combineLatest(
      self.page1ViewModel.data.map { $0?.updateTime }.asObservable(),
      self.page2ViewModel.data.map { $0?.updateTime }.asObservable())
      .map { updateTimes -> Date? in
        switch updateTimes {
        case (.some(let a), .some(let b)):
          return max(a, b)
        case (.some(let a), nil):
          return a
        case (nil, .some(let b)):
          return b
        case (nil, nil):
          return nil
        }
      }

    self.bannerBarState = Observable.combineLatest(loading, errors, updateTime) { ($0, $1, $2) }
      .map { (loading: Bool, error: AppError?, updateTime: Date?) -> AppBannerBarState in
        if loading {
          return .loading
        }

        if let updateTime = updateTime, error == nil {
          return .loaded(updateTime)
        }

        // TODO: Could check `error` and return something more helpful
        return .error("Error")
      }
      .asDriver(onErrorJustReturn: .error("Error"))
  }

  func configViewModel() -> AppConfigViewModel {
    return AppConfigViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: self.appData.uuid, appCategory: .mySolar)
  }

}
