//
//  Apps.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/12/2018.
//  Copyright © 2018 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

enum AppBannerBarState {
  case loading
  case error(String)
  case loaded(Date)
}

enum AppError: Error {
  case generic(String)
  case notConfigured
  case initialFailed
  case updateFailed
}

enum AppPageRefreshKind {
  case initial
  case update
  case dateRangeChange
}

protocol AppViewModel: AnyObject {

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI, appDataId: String)

  var title: Driver<String> { get }
  var isReady: Driver<Bool> { get }
  var accessibilityIdentifier: String { get }
  var pageViewControllerStoryboardIdentifiers: [String] { get }
  var pageViewModels: [AppPageViewModel] { get }

  func configViewModel() -> AppConfigViewModel

}

protocol AppPageViewModel: AnyObject {

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI, appDataId: String)

  var active: BehaviorRelay<Bool> { get }
  var dateRange: BehaviorRelay<DateRange> { get }
  var errors: Driver<AppError?> { get }
  var isRefreshing: Driver<Bool> { get }
  var bannerBarState: Driver<AppBannerBarState> { get }

}

typealias AppUUIDAndCategory = (uuid: String, category: AppCategory)

extension AppCategory {

  var displayName: String {
    switch self {
    case .myElectric:
      return "MyElectric"
    case .mySolar:
      return "MySolar"
    case .mySolarDivert:
      return "MySolarDivert"
    }
  }

  var viewModelInit: (RealmController, AccountController, EmonCMSAPI, String) -> AppViewModel {
    switch self {
    case .myElectric:
      return MyElectricAppViewModel.init
    case .mySolar:
      return MySolarAppViewModel.init
    case .mySolarDivert:
      return MySolarDivertAppViewModel.init
    }
  }

  var feedConfigFields: [AppConfigFieldFeed] {
    switch self {
    case .myElectric:
      return [
        AppConfigFieldFeed(id: "use", name: "Power Feed", optional: false, defaultName: "use"),
        AppConfigFieldFeed(id: "kwh", name: "kWh Feed", optional: false, defaultName: "use_kwh"),
      ]
    case .mySolar:
      return [
        AppConfigFieldFeed(id: "use", name: "Power Feed", optional: false, defaultName: "use"),
        AppConfigFieldFeed(id: "useKwh", name: "Power kWh Feed", optional: false, defaultName: "use_kwh"),
        AppConfigFieldFeed(id: "solar", name: "Solar Feed", optional: false, defaultName: "solar"),
        AppConfigFieldFeed(id: "solarKwh", name: "Solar kWh Feed", optional: false, defaultName: "solar_kwh"),
      ]
    case .mySolarDivert:
      return [
        AppConfigFieldFeed(id: "use", name: "Power Feed", optional: false, defaultName: "use"),
        AppConfigFieldFeed(id: "useKwh", name: "Power kWh Feed", optional: false, defaultName: "use_kwh"),
        AppConfigFieldFeed(id: "solar", name: "Solar Feed", optional: false, defaultName: "solar"),
        AppConfigFieldFeed(id: "solarKwh", name: "Solar kWh Feed", optional: false, defaultName: "solar_kwh"),
        AppConfigFieldFeed(id: "divert", name: "Divert Feed", optional: false, defaultName: "divert"),
        AppConfigFieldFeed(id: "divertKwh", name: "Divert kWh Feed", optional: false, defaultName: "divert_kwh"),
      ]
    }
  }

}
