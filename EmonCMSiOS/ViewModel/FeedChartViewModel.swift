//
//  FeedChartViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

final class FeedChartViewModel {
  private let account: AccountController
  private let api: EmonCMSAPI
  private let feedId: String

  private var cancellables = Set<AnyCancellable>()

  // Inputs
  @Published var active: Bool = false
  @Published var dateRange: DateRange = .relative { $0.hour = -8 }
  let refresh = PassthroughSubject<Void, Never>()

  // Outputs
  @Published private(set) var dataPoints: [DataPoint<Double>] = []
  let isRefreshing: AnyPublisher<Bool, Never>

  init(account: AccountController, api: EmonCMSAPI, feedId: String) {
    self.account = account
    self.api = api
    self.feedId = feedId

    let isRefreshingIndicator = ActivityIndicatorCombine()
    self.isRefreshing = isRefreshingIndicator.asPublisher()

    let becameActive = $active
      .filter { $0 == true }
      .removeDuplicates()
      .becomeVoid()

    let refreshSignal = Publishers.Merge(self.refresh, becameActive)

    Publishers.CombineLatest(refreshSignal, $dateRange)
      .map { $1 }
      .map { [weak self] dateRange -> AnyPublisher<[DataPoint<Double>], Never> in
        guard let self = self else { return Empty().eraseToAnyPublisher() }

        let feedId = self.feedId
        let (startDate, endDate) = dateRange.calculateDates()
        let interval = Int(endDate.timeIntervalSince(startDate) / 500)

        return self.api.feedData(self.account.credentials, id: feedId, at: startDate, until: endDate, interval: interval)
          .replaceError(with: [])
          .trackActivity(isRefreshingIndicator)
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .sink { [weak self] dataPoints in
        guard let self = self else { return }
        self.dataPoints = dataPoints
      }
      .store(in: &self.cancellables)
  }
}
