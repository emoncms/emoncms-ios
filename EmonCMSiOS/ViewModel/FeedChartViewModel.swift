//
//  FeedChartViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

final class FeedChartViewModel {

  private let account: AccountRealmController
  private let api: EmonCMSAPI
  private let feedId: String

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)
  let dateRange: BehaviorRelay<DateRange>
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var dataPoints: Driver<[DataPoint]>
  private(set) var isRefreshing: Driver<Bool>

  init(account: AccountRealmController, api: EmonCMSAPI, feedId: String) {
    self.account = account
    self.api = api
    self.feedId = feedId

    self.dateRange = BehaviorRelay<DateRange>(value: DateRange.relative(.hour8))

    self.dataPoints = Driver.empty()

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    let becameActive = self.active.asObservable()
      .filter { $0 == true }
      .distinctUntilChanged()
      .becomeVoid()

    let refreshSignal = Observable.of(self.refresh, becameActive)
      .merge()

    let dateRange = self.dateRange.asObservable()

    self.dataPoints = Observable.combineLatest(refreshSignal, dateRange) { $1 }
      .flatMapLatest { [weak self] dateRange -> Observable<[DataPoint]> in
        guard let strongSelf = self else { return Observable.empty() }

        let feedId = strongSelf.feedId

        let (startDate, endDate) = dateRange.calculateDates()
        let interval = Int(endDate.timeIntervalSince(startDate) / 500)
        return strongSelf.api.feedData(strongSelf.account, id: feedId, at: startDate, until: endDate, interval: interval)
          .catchErrorJustReturn([])
          .trackActivity(isRefreshing)
      }
      .asDriver(onErrorJustReturn: [])
  }

}
