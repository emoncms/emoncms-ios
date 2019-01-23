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
import RealmSwift

final class MyElectricAppViewModel: AppViewModel {

  typealias MyElectricData = (updateTime: Date, powerNow: Double, usageToday: Double, lineChartData: [DataPoint], barChartData: [DataPoint])

  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)

  // Outputs
  private(set) var title: Driver<String>
  private(set) var data: Driver<MyElectricData?>
  private(set) var isRefreshing: Driver<Bool>
  private(set) var isReady: Driver<Bool>
  private(set) var errors: Driver<AppError>
  private(set) var bannerBarState: Driver<AppBannerBarState>

  private var startOfDayKwh: DataPoint?
  private let errorsSubject = PublishSubject<AppError>()

  init(account: AccountController, api: EmonCMSAPI, appDataId: String) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()
    self.appData = self.realm.object(ofType: AppData.self, forPrimaryKey: appDataId)!

    self.title = Driver.empty()
    self.data = Driver.empty()
    self.isReady = Driver.empty()
    self.errors = self.errorsSubject.asDriver(onErrorJustReturn: .generic("Unknown"))
    self.bannerBarState = Driver.empty()

    self.title = self.appData.rx
      .observe(String.self, "name")
      .map { $0 ?? "" }
      .asDriver(onErrorJustReturn: "")

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    self.isReady = self.appData.rx.observe(String.self, #keyPath(AppData.name))
      .map {
        $0 != nil
      }
      .asDriver(onErrorJustReturn: false)

    let timerIfActive = self.active.asObservable()
      .distinctUntilChanged()
      .flatMapLatest { active -> Observable<Int> in
        if (active) {
          return Observable<Int>.interval(10.0, scheduler: MainScheduler.asyncInstance)
        } else {
          return Observable.never()
        }
      }
      .becomeVoid()

    let feedsChangedSignal = self.appData.rx.observe(String.self, "feedsJson")
      .distinctUntilChanged {
        $0 == $1
      }
      .becomeVoid()

    let refreshSignal = Observable.of(
        timerIfActive.map { false },
        feedsChangedSignal.map { true }
      )
      .merge()

    self.data = refreshSignal
      .flatMapFirst { [weak self] isFirst -> Observable<MyElectricData?> in
        guard let strongSelf = self else { return Observable.empty() }

        let update: Observable<MyElectricData?> = strongSelf.update()
          .catchError { [weak self] error in
            var typedError = error as? AppError ?? .generic("\(error)")
            if typedError == AppError.updateFailed && isFirst {
              typedError = .initialFailed
            }
            self?.errorsSubject.onNext(typedError)
            return Observable.empty()
          }
          .map { $0 }
          .trackActivity(isRefreshing)

        if isFirst {
          return Observable<MyElectricData?>.just(nil)
            .concat(update)
        } else {
          return update
        }
      }
      .startWith(nil)
      .asDriver(onErrorJustReturn: nil)

    let errors = self.errors.asObservable()
    let loading = self.isRefreshing.asObservable()
    let updateTime = self.data.map { $0?.updateTime }.asObservable()
    let lastErrorOrNil = Observable.combineLatest(errors, loading) { ($0, $1) }
      .map { tuple -> AppError? in
        if tuple.1 {
          return nil
        } else {
          return tuple.0
        }
      }
      .startWith(nil)

    self.bannerBarState = Observable.combineLatest(loading, lastErrorOrNil, updateTime) { ($0, $1, $2) }
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
    return AppConfigViewModel(account: self.account, api: self.api, appDataId: self.appData.uuid, appCategory: .myElectric)
  }

  private func update() -> Observable<MyElectricData> {
    guard
      let useFeedId = self.appData.feed(forName: "use"),
      let kwhFeedId = self.appData.feed(forName: "kwh")
      else {
        return Observable.error(AppError.notConfigured)
    }

    return Observable.zip(
      self.fetchPowerNowAndUsageToday(useFeedId: useFeedId, kwhFeedId: kwhFeedId),
      self.fetchLineChartHistory(useFeedId: useFeedId),
      self.fetchBarChartHistory(kwhFeedId: kwhFeedId))
    {
      (powerNowAndUsageToday, lineChartData, barChartData) in
      return MyElectricData(updateTime: Date(),
                            powerNow: powerNowAndUsageToday.0,
                            usageToday: powerNowAndUsageToday.1,
                            lineChartData: lineChartData,
                            barChartData: barChartData)
    }
    .catchError { error in
      AppLog.info("Update failed: \(error)")
      return Observable.error(AppError.updateFailed)
    }
  }

  private func fetchPowerNowAndUsageToday(useFeedId: String, kwhFeedId: String) -> Observable<(Double, Double)> {
    let calendar = Calendar.current
    let dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
    let midnightToday = calendar.date(from: dateComponents)!

    let startOfDayKwhSignal: Observable<DataPoint>
    if let startOfDayKwh = self.startOfDayKwh, startOfDayKwh.time == midnightToday {
      startOfDayKwhSignal = Observable.just(startOfDayKwh)
    } else {
      startOfDayKwhSignal = self.api.feedData(self.account.credentials, id: kwhFeedId, at: midnightToday, until: midnightToday + 1, interval: 1)
        .map { dataPoints in
          guard dataPoints.count > 0 else {
            // Assume that the data point doesn't exist, so it's a new feed, so zero
            return DataPoint(time: midnightToday, value: 0)
          }
          return dataPoints[0]
        }
        .do(onNext: { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.startOfDayKwh = $0
        })
    }

    let feedValuesSignal = self.api.feedValue(self.account.credentials, ids: [useFeedId, kwhFeedId])

    return Observable.zip(startOfDayKwhSignal, feedValuesSignal) { (startOfDayUsage, feedValues) in
      guard let use = feedValues[useFeedId], let useKwh = feedValues[kwhFeedId] else { return (0.0, 0.0) }

      return (use, useKwh - startOfDayUsage.value)
    }
  }

  private func fetchLineChartHistory(useFeedId: String) -> Observable<[DataPoint]> {
    let endTime = Date()
    let startTime = endTime - (60 * 60 * 8)
    let interval = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / 1500))

    return self.api.feedData(self.account.credentials, id: useFeedId, at: startTime, until: endTime, interval: interval)
  }

  private func fetchBarChartHistory(kwhFeedId: String) -> Observable<[DataPoint]> {
    let daysToDisplay = 15 // Needs to be 1 more than we actually want to ensure we get the right data
    let endTime = Date()
    let startTime = endTime - Double(daysToDisplay * 86400)

    return self.api.feedDataDaily(self.account.credentials, id: kwhFeedId, at: startTime, until: endTime)
      .map { dataPoints in
        guard dataPoints.count > 0 else { return [] }

        var newDataPoints: [DataPoint] = []
        var lastValue: Double = dataPoints.first?.value ?? 0

        let extraPadding = daysToDisplay - dataPoints.count
        if extraPadding > 0 {
          let thisDataPoint = dataPoints[0]
          newDataPoints.append(thisDataPoint)
          var time = thisDataPoint.time
          for _ in 1..<extraPadding {
            time = time - Double(86400)
            newDataPoints.append(DataPoint(time: time, value: 0))
          }
        }

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
