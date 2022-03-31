//
//  MyElectricAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import RealmSwift

final class MyElectricAppViewModel: AppViewModel, AppPageViewModel {
  typealias Data = (updateTime: Date, powerNow: Double, usageToday: Double, lineChartData: [DataPoint<Double>],
                    barChartData: [DataPoint<Double>])

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData

  private var cancellables = Set<AnyCancellable>()

  static let barChartDaysToDisplay = 15 // Needs to be 1 more than we actually want to ensure we get the right data

  var accessibilityIdentifier: String {
    return AccessibilityIdentifiers.Apps.MyElectric
  }

  var pageViewControllerStoryboardIdentifiers: [String] {
    return ["myElectric"]
  }

  var pageViewModels: [AppPageViewModel] {
    return [self]
  }

  // Inputs
  @Published var active = false
  @Published var dateRange = DateRange.relative { $0.hour = -1 }

  // Outputs
  let title: AnyPublisher<String, Never>
  let isReady: AnyPublisher<Bool, Never>
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

    self.title = self.appData.publisher(for: \.name)
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()

    self.isReady = self.appData.publisher(for: \.name)
      .map { $0 != "" }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()

    let timerIfActive = $active
      .map { active -> AnyPublisher<Date, Never> in
        if active {
          return Timer.publish(every: 10, on: .main, in: .common).autoconnect().eraseToAnyPublisher()
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
      dateRangeSignal.map { _ in AppPageRefreshKind.dateRangeChange })

    Publishers.CombineLatest(refreshSignal, dateRangeSignal)
      .flatMap { [weak self] refreshKind, dateRange -> AnyPublisher<Data, Never> in
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

  func configViewModel() -> AppConfigViewModel {
    return AppConfigViewModel(realmController: self.realmController, account: self.account, api: self.api,
                              appDataId: self.appData.uuid, appCategory: .myElectric)
  }

  private func update(dateRange: DateRange) -> AnyPublisher<Data, AppError> {
    guard
      let useFeedId = self.appData.feed(forName: "use"),
      let kwhFeedId = self.appData.feed(forName: "kwh")
    else {
      return Fail(error: AppError.notConfigured).eraseToAnyPublisher()
    }

    return Publishers.Zip3(
      self.fetchPowerNowAndKwhNow(useFeedId: useFeedId, kwhFeedId: kwhFeedId),
      self.fetchLineChartHistory(dateRange: dateRange, useFeedId: useFeedId),
      self.fetchBarChartHistory(kwhFeedId: kwhFeedId))
      .map {
        powerNowAndKwhNow, lineChartData, barChartData in
        Data(updateTime: Date(),
             powerNow: powerNowAndKwhNow.0,
             usageToday: powerNowAndKwhNow.1 - (barChartData.last?.value ?? 0),
             lineChartData: lineChartData,
             barChartData: ChartHelpers.processKWHData(
               barChartData,
               padTo: Self.barChartDaysToDisplay,
               interval: 86400))
      }
      .mapError { error in
        AppLog.info("Update failed: \(error)")
        return AppError.updateFailed
      }
      .eraseToAnyPublisher()
  }

  private func fetchPowerNowAndKwhNow(useFeedId: String,
                                      kwhFeedId: String) -> AnyPublisher<(Double, Double), EmonCMSAPI.APIError>
  {
    return self.api.feedValue(self.account.credentials, ids: [useFeedId, kwhFeedId])
      .map { feedValues in
        guard let use = feedValues[useFeedId], let kwh = feedValues[kwhFeedId] else { return (0.0, 0.0) }
        return (use, kwh)
      }
      .eraseToAnyPublisher()
  }

  private func fetchLineChartHistory(dateRange: DateRange,
                                     useFeedId: String) -> AnyPublisher<[DataPoint<Double>], EmonCMSAPI.APIError>
  {
    let dates = dateRange.calculateDates()
    let startTime = dates.0
    let endTime = dates.1
    let interval = Int(floor((endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) / 500))

    return self.api.feedData(self.account.credentials, id: useFeedId, at: startTime, until: endTime, interval: interval)
      .eraseToAnyPublisher()
  }

  private func fetchBarChartHistory(kwhFeedId: String) -> AnyPublisher<[DataPoint<Double>], EmonCMSAPI.APIError> {
    let endTime = Date()
    let startTime = endTime - Double(Self.barChartDaysToDisplay * 86400)

    return self.api.feedDataDaily(self.account.credentials, id: kwhFeedId, at: startTime, until: endTime)
      .eraseToAnyPublisher()
  }
}
