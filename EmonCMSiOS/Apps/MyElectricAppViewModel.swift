//
//  MyElectricAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class MyElectricAppViewModel: AppViewModel {

  typealias MyElectricData = (powerNow: Double, usageToday: Double, lineChartData: [DataPoint], barChartData: [DataPoint])

  private let account: Account
  private let api: EmonCMSAPI

  // Inputs
  let active = Variable<Bool>(false)
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var data: Driver<MyElectricData>
  private(set) var isRefreshing: Driver<Bool>

  private var useFeedId: String?
  private var useKwhFeedId: String?
  private var startOfDayKwh: DataPoint?

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api

    // TODO: These need to be found and set!
    self.useFeedId = "2"
    self.useKwhFeedId = "3"

    self.data = Driver.empty()

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    let becameActive = self.active.asObservable()
      .filter { $0 == true }
      .distinctUntilChanged()
      .becomeVoid()

    let refreshSignal = Observable.of(self.refresh, becameActive)
      .merge()

    self.data = refreshSignal
      .flatMapLatest { [weak self] () -> Observable<MyElectricData> in
        guard let strongSelf = self else { return Observable.empty() }
        return strongSelf.update()
          .trackActivity(isRefreshing)
      }
      .asDriver(onErrorJustReturn: MyElectricData(powerNow: 0.0, usageToday: 0.0, lineChartData: [], barChartData: []))
  }

  private func update() -> Observable<MyElectricData> {
    return Observable.zip(self.fetchPowerNowAndUsageToday(), self.fetchLineChartHistory(), self.fetchBarChartHistory()) {
      (powerNowAndUsageToday, lineChartData, barChartData) in
      return MyElectricData(powerNow: powerNowAndUsageToday.0,
                            usageToday: powerNowAndUsageToday.1,
                            lineChartData: lineChartData,
                            barChartData: barChartData)
    }
  }

  private func fetchPowerNowAndUsageToday() -> Observable<(Double, Double)> {
    guard let useFeedId = self.useFeedId, let useKwhFeedId = self.useKwhFeedId else {
      return Observable.empty()
    }

    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
    let midnightToday = calendar.date(from: dateComponents)!

    let startOfDayKwhSignal: Observable<DataPoint>
    if let startOfDayKwh = self.startOfDayKwh, startOfDayKwh.time == midnightToday {
      startOfDayKwhSignal = Observable.just(startOfDayKwh)
    } else {
      startOfDayKwhSignal = self.api.feedData(self.account, id: useKwhFeedId, at: midnightToday, until: midnightToday + 1, interval: 1)
        .map { $0[0] }
        .do(onNext: { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.startOfDayKwh = $0
        })
    }

    let feedValuesSignal = self.api.feedValue(self.account, ids: [useFeedId, useKwhFeedId])

    return Observable.zip(startOfDayKwhSignal, feedValuesSignal) { (startOfDayUsage, feedValues) in
      guard let use = feedValues[useFeedId], let useKwh = feedValues[useKwhFeedId] else { return (0.0, 0.0) }

      return (use, useKwh - startOfDayUsage.value)
    }
  }

  private func fetchLineChartHistory() -> Observable<[DataPoint]> {
    guard let useFeedId = self.useFeedId else {
      return Observable.empty()
    }

    let endTime = Date()
    let startTime = endTime - (60 * 60 * 8)
    let interval = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / 1500))

    return self.api.feedData(self.account, id: useFeedId, at: startTime, until: endTime, interval: interval)
  }

  private func fetchBarChartHistory() -> Observable<[DataPoint]> {
    guard let useKwhFeedId = self.useKwhFeedId else {
      return Observable.empty()
    }

    let daysToDisplay = 15 // Needs to be 1 more than we actually want to ensure we get the right data
    let endTime = Date()
    let startTime = endTime - Double(daysToDisplay * 86400)

    return self.api.feedDataDaily(self.account, id: useKwhFeedId, at: startTime, until: endTime)
      .map { dataPoints in
        guard dataPoints.count > 1 else { return [] }

        var newDataPoints: [DataPoint] = []
        var lastValue: Double = dataPoints[0].value
        for i in 1..<dataPoints.count {
          let thisDataPoint = dataPoints[i]
          let differenceValue = thisDataPoint.value - lastValue
          lastValue = thisDataPoint.value
          newDataPoints.append(DataPoint(time: thisDataPoint.time, value: differenceValue))
        }

        return newDataPoints
      }
  }

}
