//
//  FeedChartViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class FeedChartViewModel {

  private let account: Account
  private let api: EmonCMSAPI
  private let chart: Chart

  // Inputs
  let active = Variable<Bool>(false)
  let dateRange: Variable<DateRange>
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var name: Driver<String>
  private(set) var dataPoints: Driver<[DataPoint]>
  private(set) var isRefreshing: Driver<Bool>

  init(account: Account, api: EmonCMSAPI, chart: Chart) {
    self.account = account
    self.api = api
    self.chart = chart

    self.dateRange = Variable<DateRange>(chart.dateRange)

    self.name = Driver.empty()
    self.dataPoints = Driver.empty()

    self.name = self.chart.rx.observe(String.self, "name")
      .map { $0 ?? "" }
      .asDriver(onErrorJustReturn: "")

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    let becameActive = self.active.asObservable()
      .filter { $0 == true }
      .distinctUntilChanged()
      .becomeVoid()

    let refreshSignal = Observable.of(self.refresh, becameActive)
      .merge()

    let dateRange = self.dateRange.asObservable()

    self.dataPoints = Observable.combineLatest(refreshSignal, dateRange) { $1 }
      .flatMapLatest { [weak self] dateRange -> Observable<[DataPoint]> in
        guard let strongSelf = self else { return Observable.empty() }

        let startDate = dateRange.startDate()
        let endDate = dateRange.endDate()
        let interval = Int(endDate.timeIntervalSince(startDate) / 500)
        return strongSelf.api.feedData(strongSelf.account, id: strongSelf.chart.feed, at: startDate, until: endDate, interval: interval)
          .catchErrorJustReturn([])
          .trackActivity(isRefreshing)
      }
      .asDriver(onErrorJustReturn: [])
  }

}
