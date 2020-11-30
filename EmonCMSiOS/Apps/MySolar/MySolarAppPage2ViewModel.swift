//
//  MySolarAppPage2ViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import RealmSwift

final class MySolarAppPage2ViewModel: AppPageViewModel {
  typealias Data = (updateTime: Date, barChartData: (use: [DataPoint<Double>], solar: [DataPoint<Double>]))

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
          return Timer.publish(every: 60, on: .main, in: .common).autoconnect().eraseToAnyPublisher()
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
      dateRangeSignal.dropFirst().map { _ in AppPageRefreshKind.dateRangeChange })

    Publishers.CombineLatest(refreshSignal, dateRangeSignal)
      .map { [weak self] refreshKind, dateRange -> AnyPublisher<Data, Never> in
        guard let self = self else { return Empty().eraseToAnyPublisher() }

        let update = self.update(dateRange: dateRange)
          .catch { [weak self] error -> AnyPublisher<Data, Never> in
            let actualError: AppError
            if error == AppError.updateFailed, refreshKind == .initial {
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
          .trackActivity(isRefreshingIndicator)
          .eraseToAnyPublisher()

        return update
      }
      .switchToLatest()
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
      let useFeedId = self.appData.feed(forName: "useKwh"),
      let solarFeedId = self.appData.feed(forName: "solarKwh")
    else {
      return Fail(error: AppError.notConfigured).eraseToAnyPublisher()
    }

    return self.fetchBarChartHistory(dateRange: dateRange, useFeedId: useFeedId, solarFeedId: solarFeedId)
      .map { lineChartData in
        Data(updateTime: Date(), barChartData: lineChartData)
      }
      .mapError { error in
        AppLog.info("Update failed: \(error)")
        return AppError.updateFailed
      }
      .eraseToAnyPublisher()
  }

  private func fetchBarChartHistory(dateRange: DateRange, useFeedId: String,
                                    solarFeedId: String) -> AnyPublisher<([DataPoint<Double>], [DataPoint<Double>]),
                                                                         EmonCMSAPI.APIError> {
    let dates = dateRange.calculateDates()
    let interval = 86400.0
    let startTime = dates.0 - interval
    let endTime = dates.1
    let daysToDisplay = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / interval))

    let use = self.api.feedDataDaily(self.account.credentials, id: useFeedId, at: startTime, until: endTime)
      .map { dataPoints in
        ChartHelpers.processKWHData(dataPoints, padTo: daysToDisplay, interval: interval)
      }
    let solar = self.api.feedDataDaily(self.account.credentials, id: solarFeedId, at: startTime, until: endTime)
      .map { dataPoints in
        ChartHelpers.processKWHData(dataPoints, padTo: daysToDisplay, interval: interval)
      }

    return Publishers.Zip(use, solar).eraseToAnyPublisher()
  }
}
