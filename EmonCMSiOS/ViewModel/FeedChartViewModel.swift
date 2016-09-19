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

struct FeedChartParameters {

  enum DateRangeType {
    case absolute(Date, Date)
    case relative(Date, TimeInterval)
    case relativeToNow(TimeInterval)

    func startDate() -> Date {
      switch self {
      case .absolute(let startDate, _):
        return startDate
      case .relative(let endDate, let interval):
        return endDate - interval
      case .relativeToNow(let interval):
        return Date() - interval
      }
    }

    func endDate() -> Date {
      switch self {
      case .absolute(_, let endDate):
        return endDate
      case .relative(let endDate, _):
        return endDate
      case .relativeToNow(_):
        return Date()
      }
    }
  }

  let dateRange: DateRangeType

}

class FeedChartViewModel {

  private let account: Account
  private let api: EmonCMSAPI
  private let feed: Feed

  // Inputs
  let active = Variable<Bool>(false)
  let updateParameters = ReplaySubject<FeedChartParameters>.create(bufferSize: 1)

  // Outputs
  private(set) var name: Driver<String>
  private(set) var dataPoints: Driver<[DataPoint]>

  init(account: Account, api: EmonCMSAPI, feed: Feed) {
    self.account = account
    self.api = api
    self.feed = feed

    self.name = Driver.empty()
    self.dataPoints = Driver.empty()

    self.name = self.feed.rx.observe(String.self, "name")
      .map { $0 ?? "" }
      .asDriver(onErrorJustReturn: "")

    let active = self.active.asObservable()
    let updateParameters = self.updateParameters

    self.dataPoints = Observable.combineLatest(active, updateParameters) { ($0, $1) }
      .filter { $0.0 == true }
      .map { $0.1 }
      .flatMapLatest { [weak self] data -> Observable<[DataPoint]> in
        guard let strongSelf = self else { return Observable.empty() }

        let startDate = data.dateRange.startDate()
        let endDate = data.dateRange.endDate()
        let interval = Int(endDate.timeIntervalSince(startDate) / 500)
        return strongSelf.api.feedData(strongSelf.account, id: strongSelf.feed.id, at: startDate, until: endDate, interval: interval)
          .catchErrorJustReturn([])
      }
      .asDriver(onErrorJustReturn: [])
  }

}
