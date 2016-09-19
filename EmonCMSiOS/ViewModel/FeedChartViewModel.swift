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
  let startDate: Date
  let endDate: Date
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

        let interval = Int(data.endDate.timeIntervalSince(data.startDate) / 500)
        return strongSelf.api.feedData(strongSelf.account, id: strongSelf.feed.id, at: data.startDate, until: data.endDate, interval: interval)
          .catchErrorJustReturn([])
      }
      .asDriver(onErrorJustReturn: [])
  }

}
