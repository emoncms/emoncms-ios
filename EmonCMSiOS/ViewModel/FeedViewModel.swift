//
//  FeedViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

class FeedViewModel {

  private let api: EmonCMSAPI
  private let feed: Feed

  init(api: EmonCMSAPI, feed: Feed) {
    self.api = api
    self.feed = feed
  }

  var name: String {
    return self.feed.name
  }

  var value: String {
    return self.feed.value.prettyFormat()
  }

  func fetchData(at startTime: Date, until endTime: Date, interval: Int) -> Observable<[FeedDataPoint]> {
    return self.api.feedData(id: self.feed.id, at: startTime, until: endTime, interval: interval)
  }

}
