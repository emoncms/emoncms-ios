//
//  FeedViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import Realm

class FeedViewModel {

  private let account: Account
  private let api: EmonCMSAPI
  private let feed: Feed

  private let disposeBag = DisposeBag()

  let name = Variable<String>("")
  let value = Variable<String>("")

  init(account: Account, api: EmonCMSAPI, feed: Feed) {
    self.account = account
    self.api = api
    self.feed = feed

    self.feed.rx.observe(String.self, "name")
      .map { $0 ?? "" }
      .bindTo(self.name)
      .addDisposableTo(self.disposeBag)

    self.feed.rx.observe(Double.self, "value")
      .map { $0 ?? 0 }
      .map { $0.prettyFormat() }
      .bindTo(self.value)
      .addDisposableTo(self.disposeBag)
  }

  func fetchData(at startTime: Date, until endTime: Date, interval: Int) -> Observable<[FeedDataPoint]> {
    return self.api.feedData(account, id: self.feed.id, at: startTime, until: endTime, interval: interval)
  }

}
