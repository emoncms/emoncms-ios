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
      accountName: "---",
      feedId: "1",
      feedName: "---",
      feedChartData: [])
  }
}

extension FeedWidgetItem: Identifiable {
  var id: String {
    return self.accountId + "/" + self.feedId
  }
}

enum FeedWidgetItemError: Error {
  case unknown
  case noFeedInfo
  case fetchFailed(FeedViewModel.FeedViewModelError)
}

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
