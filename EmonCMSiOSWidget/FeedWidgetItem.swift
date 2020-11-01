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

  static func makePlaceholder() -> FeedWidgetItem {
    FeedWidgetItem(
      accountId: "1",
      accountName: "EmonCMS",
      feedId: "1",
      feedName: self.placeholderFeedNames.randomElement() ?? "Feed name",
      feedChartData: Self.randomChartData())
  }

  private static var placeholderFeedNames = [
    "Total use",
    "Divert use",
    "Solar generation",
    "Wind generation",
    "Temperature",
    "Outside temperature"
  ]

  private static func randomChartData() -> [DataPoint<Double>] {
    let sectionCount = 5
    let sectionLengths = (0 ..< sectionCount).map { _ in Int.random(in: 5 ..< 30) }
    return sectionLengths.reduce([DataPoint<Double>]()) { result, length in
      let lastDataPoint = result.last
      let startTime = lastDataPoint?.time ?? Date(timeIntervalSince1970: 0)
      let lastValue = lastDataPoint?.value ?? Double.random(in: 0 ..< 50)
      let startValue = lastValue
      let nextMinValue = max(lastValue - 25, 0)
      let endValue = Double.random(in: nextMinValue ..< nextMinValue + 50)
      let section = Self.randomChartData(between: startValue, and: endValue, count: length, startTime: startTime)
      return result + section
    }
  }

  private static func randomChartData(between start: Double, and end: Double, count: Int,
                                      startTime: Date) -> [DataPoint<Double>] {
    let maxDivergence = abs(end - start) / 5.0
    return (0 ..< count).reduce(into: [DataPoint<Double>]()) { result, i in
      let time = startTime.addingTimeInterval(TimeInterval(i))

      let interpolatedValue = start + (Double(i) * (end - start) / Double(count))
      let divergence = Double.random(in: -maxDivergence ..< maxDivergence)
      let offsetValue = interpolatedValue + divergence
      let value = offsetValue

      result.append(DataPoint<Double>(time: time, value: value))
    }
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

  var displayTitle: String {
    return "Error loading data"
  }

  var displayDescription: String {
    switch self {
    case .noFeedInfo, .unknown:
      return "Select a feed"
    case .fetchFailed(let error):
      switch error {
      case .unknown:
        return "Connection error"
      case .invalidFeed:
        return "Invalid feed"
      case .keychainLocked:
        return "Keychain locked"
      }
    }
  }
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
