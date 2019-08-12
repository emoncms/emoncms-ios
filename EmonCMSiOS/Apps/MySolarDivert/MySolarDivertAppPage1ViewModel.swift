//
//  MySolarDivertAppPage1ViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import RealmSwift

final class MySolarDivertAppPage1ViewModel: AppPageViewModel {

  typealias Data = (updateTime: Date, houseNow: Double, divertNow: Double, totalUseNow: Double, importNow: Double, solarNow: Double, lineChartData: (use: [DataPoint<Double>], solar: [DataPoint<Double>], divert: [DataPoint<Double>]))

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData

  private var cancellables = Set<AnyCancellable>()

  // Inputs
  @Published var active = false
  @Published var dateRange = DateRange.relative { $0.hour = -1 }

  // Outputs
  @Published private(set) var data: Data? = nil
  var errors: AnyPublisher<AppError?, Never> { return self.errorsSubject.eraseToAnyPublisher() }
  private let errorsSubject = CurrentValueSubject<AppError?, Never>(nil)
  var bannerBarState: AnyPublisher<AppBannerBarState, Never> { return self.bannerBarStateSubject.eraseToAnyPublisher() }
  private let bannerBarStateSubject = CurrentValueSubject<AppBannerBarState, Never>(.loading)
  let isRefreshing: AnyPublisher<Bool, Never>

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI, appDataId: String) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.appData = self.realm.object(ofType: AppData.self, forPrimaryKey: appDataId)!

    let isRefreshingIndicator = ActivityIndicatorCombine()
    self.isRefreshing = isRefreshingIndicator.asPublisher()

    let timerIfActive = $active
      .map { active -> AnyPublisher<Date, Never> in
        if active {
          return Timer.publish(every: 10, on: .main, in: .common).eraseToAnyPublisher()
        } else {
          return Empty(completeImmediately: false).eraseToAnyPublisher()
        }
      }
      .switchToLatest()
      .becomeVoid()

    let feedsChangedSignal = self.appData.feedsChanged
    let dateRangeSignal = $dateRange.dropFirst()

    let refreshSignal = Publishers.Merge3(
      timerIfActive.map { AppPageRefreshKind.update },
      feedsChangedSignal.map { AppPageRefreshKind.initial },
      dateRangeSignal.map { _ in AppPageRefreshKind.dateRangeChange }
    )

    Publishers.CombineLatest(refreshSignal, dateRangeSignal)
      .flatMap { [weak self] refreshKind, dateRange -> AnyPublisher<Data, Never> in
          guard let self = self else { return Empty().eraseToAnyPublisher() }

          let update = self.update(dateRange: dateRange)
            .catch { [weak self] error -> AnyPublisher<Data, Never> in
              let actualError: AppError
              if error == AppError.updateFailed && refreshKind == .initial {
                actualError = .initialFailed
              } else {
                actualError = error
              }
              self?.errorsSubject.send(actualError)
              return Empty().eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] _ in
              self?.errorsSubject.send(nil)
            })
            .map { $0 }
            .prefix(untilOutputFrom: self.$dateRange.dropFirst())
            .trackActivity(isRefreshingIndicator)
            .eraseToAnyPublisher()

          return update
        }
        .map { $0 as Data? }
        .assign(to: \Self.data, on: self)
        .store(in: &self.cancellables)

    let loading = self.isRefreshing
    let errors = self.errors
    let updateTime = $data.map { $0?.updateTime }

    Publishers.CombineLatest3(loading, errors, updateTime)
      .prepend((true, nil, nil))
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
      .sink(receiveValue: { [weak self] state in
        guard let self = self else { return }
        self.bannerBarStateSubject.send(state)
      })
      .store(in: &self.cancellables)
  }

  private func update(dateRange: DateRange) -> AnyPublisher<Data, AppError> {
    guard
      let useFeedId = self.appData.feed(forName: "use"),
      let solarFeedId = self.appData.feed(forName: "solar"),
      let divertFeedId = self.appData.feed(forName: "divert")
    else {
      return Fail(error: AppError.notConfigured).eraseToAnyPublisher()
    }

    return Publishers.Zip(
      self.fetchPowerNow(useFeedId: useFeedId, solarFeedId: solarFeedId, divertFeedId: divertFeedId),
      self.fetchLineChartHistory(dateRange: dateRange, useFeedId: useFeedId, solarFeedId: solarFeedId, divertFeedId: divertFeedId)
    )
    .map {
      (powerNow, lineChartData) in
      return Data(updateTime: Date(),
                  houseNow: powerNow.0,
                  divertNow: powerNow.1,
                  totalUseNow: powerNow.2,
                  importNow: powerNow.3,
                  solarNow: powerNow.4,
                  lineChartData: lineChartData)
    }
    .mapError { error in
      AppLog.info("Update failed: \(error)")
      return AppError.updateFailed
    }
    .eraseToAnyPublisher()
  }

  private func fetchPowerNow(useFeedId: String, solarFeedId: String, divertFeedId: String) -> AnyPublisher<(Double, Double, Double, Double, Double), EmonCMSAPI.APIError> {
    return self.api.feedValue(self.account.credentials, ids: [useFeedId, solarFeedId, divertFeedId])
      .map { feedValues in
        guard let use = feedValues[useFeedId], let solar = feedValues[solarFeedId], let divert = feedValues[divertFeedId] else { return (0.0, 0.0, 0.0, 0.0, 0.0) }

        return (use-divert, divert, use, use-solar, solar)
      }
      .eraseToAnyPublisher()
  }

  private func fetchLineChartHistory(dateRange: DateRange, useFeedId: String, solarFeedId: String, divertFeedId: String) -> AnyPublisher<([DataPoint<Double>], [DataPoint<Double>], [DataPoint<Double>]), EmonCMSAPI.APIError> {
    let dates = dateRange.calculateDates()
    let startTime = dates.0
    let endTime = dates.1
    let interval = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / 500))

    let use = self.api.feedData(self.account.credentials, id: useFeedId, at: startTime, until: endTime, interval: interval)
    let solar = self.api.feedData(self.account.credentials, id: solarFeedId, at: startTime, until: endTime, interval: interval)
    let divert = self.api.feedData(self.account.credentials, id: divertFeedId, at: startTime, until: endTime, interval: interval)

    return Publishers.Zip3(use, solar, divert).eraseToAnyPublisher()
  }

}
