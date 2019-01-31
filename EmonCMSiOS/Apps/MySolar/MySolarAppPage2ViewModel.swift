//
//  MySolarAppPage2ViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class MySolarAppPage2ViewModel {

  typealias Data = (updateTime: Date, barChartData: (use: [DataPoint<Double>], solar: [DataPoint<Double>]))

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)
  let dateRange = BehaviorRelay<DateRange>(value: DateRange.relative { $0.weekOfYear = -1 })

  // Outputs
  private(set) var data: Driver<Data?>
  private(set) var isRefreshing: Driver<Bool>
  private(set) var errors: Driver<AppError?>

  private let errorsSubject = PublishSubject<AppError?>()

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI, appDataId: String) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.appData = self.realm.object(ofType: AppData.self, forPrimaryKey: appDataId)!

    self.data = Driver.empty()
    self.errors = self.errorsSubject.asDriver(onErrorJustReturn: .generic("Unknown"))

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

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

    self.data = Observable.combineLatest(refreshSignal, self.dateRange)
      .flatMap { [weak self] isFirst, dateRange -> Observable<Data?> in
        guard let strongSelf = self else { return Observable.empty() }

        let update: Observable<Data?> = strongSelf.update(dateRange: dateRange)
          .catchError { [weak self] error in
            var typedError = error as? AppError ?? .generic("\(error)")
            if typedError == AppError.updateFailed && isFirst {
              typedError = .initialFailed
            }
            self?.errorsSubject.onNext(typedError)
            return Observable.empty()
          }
          .do(onNext: { [weak self] _ in
            self?.errorsSubject.onNext(nil)
          })
          .map { $0 }
          .takeUntil(strongSelf.dateRange.skip(1))
          .trackActivity(isRefreshing)

        if isFirst {
          return Observable<Data?>.just(nil)
            .concat(update)
        } else {
          return update
        }
      }
      .startWith(nil)
      .asDriver(onErrorJustReturn: nil)
  }

  private func update(dateRange: DateRange) -> Observable<Data> {
    guard
      let useFeedId = self.appData.feed(forName: "useKwh"),
      let solarFeedId = self.appData.feed(forName: "solarKwh")
    else {
      return Observable.error(AppError.notConfigured)
    }

    return self.fetchBarChartHistory(dateRange: dateRange, useFeedId: useFeedId, solarFeedId: solarFeedId)
      .map { lineChartData in
        return Data(updateTime: Date(), barChartData: lineChartData)
      }
      .catchError { error in
        AppLog.info("Update failed: \(error)")
        return Observable.error(AppError.updateFailed)
      }
  }

  private func fetchBarChartHistory(dateRange: DateRange, useFeedId: String, solarFeedId: String) -> Observable<([DataPoint<Double>], [DataPoint<Double>])> {
    let dates = dateRange.calculateDates()
    let interval = 86400.0
    let startTime = dates.0 - interval
    let endTime = dates.1
    let daysToDisplay = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / interval))

    let use = self.api.feedDataDaily(self.account.credentials, id: useFeedId, at: startTime, until: endTime)
      .map { dataPoints in
        return ChartHelpers.processKWHData(dataPoints, padTo: daysToDisplay, interval: interval)
    }
    let solar = self.api.feedDataDaily(self.account.credentials, id: solarFeedId, at: startTime, until: endTime)
      .map { dataPoints in
        return ChartHelpers.processKWHData(dataPoints, padTo: daysToDisplay, interval: interval)
    }

    return Observable.zip(use, solar)
  }

}
