//
//  MySolarAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/12/2018.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class MySolarAppViewModel: AppViewModel {

  typealias MySolarData = (updateTime: Date, useNow: Double, importNow: Double, solarNow: Double, lineChartData: (use: [DataPoint<Double>], solar: [DataPoint<Double>]))

  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)

  // Outputs
  private(set) var title: Driver<String>
  private(set) var data: Driver<MySolarData?>
  private(set) var isRefreshing: Driver<Bool>
  private(set) var isReady: Driver<Bool>
  private(set) var errors: Driver<AppError>
  private(set) var bannerBarState: Driver<AppBannerBarState>

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
      .flatMapFirst { [weak self] isFirst -> Observable<MySolarData?> in
        guard let strongSelf = self else { return Observable.empty() }

        let update: Observable<MySolarData?> = strongSelf.update()
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
          return Observable<MySolarData?>.just(nil)
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
    return AppConfigViewModel(account: self.account, api: self.api, appDataId: self.appData.uuid, appCategory: .mySolar)
  }

  private func update() -> Observable<MySolarData> {
    guard
      let useFeedId = self.appData.feed(forName: "use"),
      let solarFeedId = self.appData.feed(forName: "solar")
    else {
      return Observable.error(AppError.notConfigured)
    }

    return Observable.zip(
      self.fetchPowerNow(useFeedId: useFeedId, solarFeedId: solarFeedId),
      self.fetchLineChartHistory(useFeedId: useFeedId, solarFeedId: solarFeedId))
    {
      (powerNow, lineChartData) in
      return MySolarData(updateTime: Date(),
                         useNow: powerNow.0,
                         importNow: powerNow.1,
                         solarNow: powerNow.2,
                         lineChartData: lineChartData)
    }
    .catchError { error in
      AppLog.info("Update failed: \(error)")
      return Observable.error(AppError.updateFailed)
    }
  }

  private func fetchPowerNow(useFeedId: String, solarFeedId: String) -> Observable<(Double, Double, Double)> {
    return self.api.feedValue(self.account.credentials, ids: [useFeedId, solarFeedId])
      .map { feedValues in
        guard let use = feedValues[useFeedId], let solar = feedValues[solarFeedId] else { return (0.0, 0.0, 0.0) }

        return (use, use - solar, solar)
    }
  }

  private func fetchLineChartHistory(useFeedId: String, solarFeedId: String) -> Observable<([DataPoint<Double>], [DataPoint<Double>])> {
    let endTime = Date()
    let startTime = endTime - (60 * 60 * 8)
    let interval = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / 1500))

    let use = self.api.feedData(self.account.credentials, id: useFeedId, at: startTime, until: endTime, interval: interval)
    let solar = self.api.feedData(self.account.credentials, id: solarFeedId, at: startTime, until: endTime, interval: interval)

    return Observable.zip(use, solar)
  }

}
