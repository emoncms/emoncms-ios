//
//  Apps.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/12/2018.
//  Copyright © 2018 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift

protocol AppViewModel: AnyObject {

  init(account: Account, api: EmonCMSAPI, appDataId: String)

}

typealias AppUUIDAndCategory = (uuid: String, category: AppCategory)

enum AppCategory: String, CaseIterable {

  case myElectric
  case mySolar

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
    }
  }

}
