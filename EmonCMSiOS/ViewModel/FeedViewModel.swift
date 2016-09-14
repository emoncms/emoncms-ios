//
//  FeedViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

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

  func fetchData(at startTime: Date, until endTime: Date, interval: Int, callback: @escaping ([FeedDataPoint]) -> Void) {
    self.api.feedData(id: self.feed.id, at: startTime, until: endTime, interval: interval) { result in
      switch result {
      case .Result(let feedDataPoints):
        callback(feedDataPoints)
      case .Error:
        callback([])
      }
    }
  }

}
