//
//  AccessibilityIdentifiers.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

struct AccessibilityIdentifiers {
  enum Lists {
    static let Account = "AccountList"
    static let App = "AppList"
    static let Feed = "FeedList"
    static let Input = "InputList"
    static let Dashboard = "DashboardList"
    static let TodayWidgetFeed = "TodayWidgetFeedList"
    static let AppSelectFeed = "AppSelectFeedList"
  }

  enum Apps {
    static let MyElectric = "MyElectricApp"
    static let MySolar = "MySolar"
    static let MySolarDivert = "MySolarDivert"

    static let TimeBannerLabel = "AppsTimeBannerLabel"
  }

  enum FeedList {
    static let ChartContainer = "FeedListChartContainer"
  }

  static let AddAccountQRView = "AddAccountQRView"
  static let FeedChartView = "FeedChartView"
  static let Settings = "Settings"
}
