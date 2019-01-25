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

protocol AppViewModel: AnyObject {

  init(account: AccountController, api: EmonCMSAPI, appDataId: String)

  var active: BehaviorRelay<Bool> { get }
  var title: Driver<String> { get }
  var errors: Driver<AppError> { get }
  var isRefreshing: Driver<Bool> { get }
  var isReady: Driver<Bool> { get }
  var bannerBarState: Driver<AppBannerBarState> { get }
  var dateRange: BehaviorRelay<DateRange> { get }

  func configViewModel() -> AppConfigViewModel

}

typealias AppUUIDAndCategory = (uuid: String, category: AppCategory)

enum AppCategory: String, CaseIterable {

  case myElectric
  case mySolar
  case mySolarDivert

  struct Info {
    let displayName: String
    let storyboardId: String
  }

  var info: Info {
    switch self {
    case .myElectric:
      return Info(
        displayName: "MyElectric",
        storyboardId: "myElectric"
      )
    case .mySolar:
      return Info(
        displayName: "MySolar",
        storyboardId: "mySolar"
      )
    case .mySolarDivert:
      return Info(
        displayName: "MySolarDivert",
        storyboardId: "mySolarDivert"
      )
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
