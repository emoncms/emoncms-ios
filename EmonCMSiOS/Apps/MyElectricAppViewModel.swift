//
//  MyElectricAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

class MyElectricAppViewModel: AppViewModel {

  private let account: Account
  private let api: EmonCMSAPI

  let powerNow = Variable<Double>(0)
  let usageToday = Variable<Double>(0)
  let lineChartData = Variable<[DataPoint]>([])
  let barChartData = Variable<[DataPoint]>([])

  private var useFeedId: String?
  private var useKwhFeedId: String?

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api

    // TODO: These need to be found and set!
    self.useFeedId = "2"
    self.useKwhFeedId = "3"
  }

  func updatePowerAndUsage() -> Observable<()> {
    guard let useFeedId = self.useFeedId, let useKwhFeedId = self.useKwhFeedId else {
      return Observable.empty()
    }

    return self.api.feedValue(self.account, ids: [useFeedId, useKwhFeedId])
      .do(onNext: { [weak self] results in
        guard let strongSelf = self else { return }

        guard let use = results[useFeedId], let useKwh = results[useKwhFeedId] else {
          return
        }

        strongSelf.powerNow.value = use
        strongSelf.usageToday.value = useKwh // TODO: Obviously this isn't right
      })
      .becomeVoidAndIgnoreElements()
  }

  func updateChartData() -> Observable<()> {
    let lineChart = self.fetchLineChartHistory()
      .do(onNext: { [weak self] data in
        guard let strongSelf = self else { return }

        strongSelf.lineChartData.value = data
        })

    let barChart = self.fetchBarChartHistory()
      .do(onNext: { [weak self] data in
        guard let strongSelf = self else { return }

        strongSelf.barChartData.value = data
        })

    return Observable.of(lineChart, barChart)
      .merge()
      .becomeVoidAndIgnoreElements()
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
