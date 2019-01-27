//
//  MySolarDivertAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class MySolarDivertAppViewModel: AppViewModel {

  typealias MySolarDivertData = (updateTime: Date, houseNow: Double, divertNow: Double, totalUseNow: Double, importNow: Double, solarNow: Double, lineChartData: (use: [DataPoint<Double>], solar: [DataPoint<Double>], divert: [DataPoint<Double>]))

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)
  let dateRange = BehaviorRelay<DateRange>(value: .relative(.hour1))

  // Outputs
  private(set) var title: Driver<String>
  private(set) var data: Driver<MySolarDivertData?>
  private(set) var isRefreshing: Driver<Bool>
  private(set) var isReady: Driver<Bool>
  private(set) var errors: Driver<AppError?>
  private(set) var bannerBarState: Driver<AppBannerBarState>

  private let errorsSubject = PublishSubject<AppError?>()

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI, appDataId: String) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.appData = self.realm.object(ofType: AppData.self, forPrimaryKey: appDataId)!

    self.title = Driver.empty()
    self.data = Driver.empty()
    self.isReady = Driver.empty()
    self.errors = self.errorsSubject.asDriver(onErrorJustReturn: .generic("Unknown"))
    self.bannerBarState = Driver.empty()

    self.title = self.appData.rx
      .observe(String.self, #keyPath(AppData.name))
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
        feedsChangedSignal.map { true },
        self.dateRange.map { _ in return false }
      )
      .merge()

    self.data = refreshSignal
      .flatMapFirst { [weak self] isFirst -> Observable<MySolarDivertData?> in
        guard let strongSelf = self else { return Observable.empty() }

        let update: Observable<MySolarDivertData?> = strongSelf.update()
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
          .trackActivity(isRefreshing)

        if isFirst {
          return Observable<MySolarDivertData?>.just(nil)
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

    self.bannerBarState = Observable.combineLatest(loading, errors, updateTime) { ($0, $1, $2) }
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
    return AppConfigViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: self.appData.uuid, appCategory: .mySolarDivert)
  }

  private func update() -> Observable<MySolarDivertData> {
    guard
      let useFeedId = self.appData.feed(forName: "use"),
      let solarFeedId = self.appData.feed(forName: "solar"),
      let divertFeedId = self.appData.feed(forName: "divert")
    else {
      return Observable.error(AppError.notConfigured)
    }

    let dateRange = self.dateRange.value

    return Observable.zip(
      self.fetchPowerNow(useFeedId: useFeedId, solarFeedId: solarFeedId, divertFeedId: divertFeedId),
      self.fetchLineChartHistory(dateRange: dateRange, useFeedId: useFeedId, solarFeedId: solarFeedId, divertFeedId: divertFeedId))
    {
      (powerNow, lineChartData) in
      return MySolarDivertData(updateTime: Date(),
                               houseNow: powerNow.0,
                               divertNow: powerNow.1,
                               totalUseNow: powerNow.2,
                               importNow: powerNow.3,
                               solarNow: powerNow.4,
                               lineChartData: lineChartData)
    }
    .catchError { error in
      AppLog.info("Update failed: \(error)")
      return Observable.error(AppError.updateFailed)
    }
  }

  private func fetchPowerNow(useFeedId: String, solarFeedId: String, divertFeedId: String) -> Observable<(Double, Double, Double, Double, Double)> {
    return self.api.feedValue(self.account.credentials, ids: [useFeedId, solarFeedId, divertFeedId])
      .map { feedValues in
        guard let use = feedValues[useFeedId], let solar = feedValues[solarFeedId], let divert = feedValues[divertFeedId] else { return (0.0, 0.0, 0.0, 0.0, 0.0) }

        return (use-divert, divert, use, use-solar, solar)
    }
  }

  private func fetchLineChartHistory(dateRange: DateRange, useFeedId: String, solarFeedId: String, divertFeedId: String) -> Observable<([DataPoint<Double>], [DataPoint<Double>], [DataPoint<Double>])> {
    let dates = dateRange.calculateDates()
    let startTime = dates.0
    let endTime = dates.1
    let interval = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / 500))

    let use = self.api.feedData(self.account.credentials, id: useFeedId, at: startTime, until: endTime, interval: interval)
    let solar = self.api.feedData(self.account.credentials, id: solarFeedId, at: startTime, until: endTime, interval: interval)
    let divert = self.api.feedData(self.account.credentials, id: divertFeedId, at: startTime, until: endTime, interval: interval)

    return Observable.zip(use, solar, divert)
  }

}
