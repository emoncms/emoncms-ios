//
//  FeedListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import RxRealm

class ChartListViewModel {

  struct ChartListItem {
    fileprivate let chart: Chart

    var name: String {
      return self.chart.name
    }

    init(chart: Chart) {
      self.chart = chart
    }
  }

  private let account: Account
  private let api: EmonCMSAPI
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs

  // Outputs
  private(set) var charts: Driver<[ChartListItem]>

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()

    self.charts = Driver.never()

    self.charts = Observable.arrayFrom(self.realm.objects(Chart.self))
      .map {
        $0.map { ChartListItem(chart: $0) }
      }
      .asDriver(onErrorJustReturn: [])
  }

  private func chartsToItems(_ charts: [Chart]) -> [ChartListItem] {
    return charts.map { ChartListItem(chart: $0) }
  }

  func feedChartViewModel(forItem item: ChartListItem) -> FeedChartViewModel {
    return FeedChartViewModel(account: self.account, api: self.api, chart: item.chart)
  }

}
