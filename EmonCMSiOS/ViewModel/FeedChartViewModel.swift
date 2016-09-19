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

class FeedChartViewModel {

  private let account: Account
  private let api: EmonCMSAPI
  private let feed: Feed

  // Inputs

  // Outputs
  let name: Driver<String>

  init(account: Account, api: EmonCMSAPI, feed: Feed) {
    self.account = account
    self.api = api
    self.feed = feed

    self.name = self.feed.rx.observe(String.self, "name")
      .map { $0 ?? "" }
      .asDriver(onErrorJustReturn: "")
  }

  func fetchData(at startTime: Date, until endTime: Date, interval: Int) -> Observable<[DataPoint]> {
    return self.api.feedData(account, id: self.feed.id, at: startTime, until: endTime, interval: interval)
  }

}
