//
//  FeedWidgetItem.swift
//  EmonCMSiOSWidgetExtension
//
//  Created by Matt Galloway on 19/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Foundation

struct FeedWidgetItem {
  let accountId: String
  let accountName: String
  let feedId: String
  let feedName: String
  let feedChartData: [DataPoint<Double>]

  static var placeholder: FeedWidgetItem {
    FeedWidgetItem(
      accountId: "1",
      accountName: "EmonCMS",
      feedId: "1",
      feedName: "Solar",
      feedChartData: [
        DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 0),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 4),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 2),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 5),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 6), value: 6),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 7), value: 4),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 8), value: 7),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 9), value: 6),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 10), value: 3),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 11), value: 4),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 12), value: 6),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 13), value: 8),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 14), value: 7)
      ])
  }
}

extension FeedWidgetItem: Identifiable {
  var id: String {
    return self.accountId + "/" + self.feedId
  }
}

extension FeedWidgetItem: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(self.accountId)
    hasher.combine(self.feedId)
  }
}

enum FeedWidgetItemError: Error {
  case unknown
  case noFeedInfo
  case fetchFailed(FeedViewModel.FeedViewModelError)
}

extension FeedWidgetItemError: Equatable {}

enum FeedWidgetItemResult {
  case success(FeedWidgetItem)
  case failure(FeedWidgetItemError)
}

extension FeedWidgetItemResult: Identifiable {
  var id: String {
    switch self {
    case .success(let item):
      return item.id
    case .failure(let error):
      return error.localizedDescription
    }
  }
}

extension FeedWidgetItemResult: Equatable {
  static func == (lhs: FeedWidgetItemResult, rhs: FeedWidgetItemResult) -> Bool {
    switch (lhs, rhs) {
    case (.success(let item1), .success(let item2)):
      return item1 == item2
    case (.failure(let error1), .failure(let error2)):
      return error1 == error2
    default:
      return false
    }
  }
}

extension FeedWidgetItemResult: Hashable {
  func hash(into hasher: inout Hasher) {
    switch self {
    case .success(let item):
      hasher.combine(item)
    case .failure:
      hasher.combine("error")
    }
  }
}
