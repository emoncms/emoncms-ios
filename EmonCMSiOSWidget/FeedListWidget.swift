//
//  FeedListWidget.swift
//  EmonCMSiOSWidget
//
//  Created by Matt Galloway on 19/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import SwiftUI
import WidgetKit

struct FeedListProvider: IntentTimelineProvider {
  private let viewModel: FeedViewModel

  init() {
    let dataDirectory = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.SharedApplicationGroupIdentifier)!
    let realmController = RealmController(dataDirectory: dataDirectory)
    let requestProvider = NSURLSessionHTTPRequestProvider()
    let api = EmonCMSAPI(requestProvider: requestProvider)
    self.viewModel = FeedViewModel(realmController: realmController, api: api)
  }

  func placeholder(in context: Context) -> FeedListEntry {
    let rows = FeedListView.rowsForFamily[context.family]!
    let items = (0 ..< rows).map { _ in FeedWidgetItemResult.success(FeedWidgetItem.placeholder) }
    return FeedListEntry(date: Date(), items: items)
  }

  func getSnapshot(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping (FeedListEntry) -> Void) {
    self.fetchData(for: configuration, in: context) { results in
      let entry = FeedListEntry(date: Date(), items: results)
      completion(entry)
    }
  }

  func getTimeline(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping (Timeline<FeedListEntry>) -> Void) {
    self.fetchData(for: configuration, in: context) { results in
      let entry = FeedListEntry(date: Date(), items: results)
      let expiry = Calendar.current.date(byAdding: .minute, value: 2, to: Date()) ?? Date()
      let timeline = Timeline(entries: [entry], policy: .after(expiry))
      completion(timeline)
    }
  }

  private func fetchData(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping ([FeedWidgetItemResult]) -> Void) {
    guard !context.isPreview else {
      let rows = FeedListView.rowsForFamily[context.family]!
      completion(Array(repeating: FeedWidgetItemResult.success(FeedWidgetItem.placeholder), count: rows))
      return
    }

    guard let feeds = configuration.feeds else {
      completion([])
      return
    }

    let zipped = feeds.compactMap { feed -> (accountId: String, feedId: String)? in
      guard
        let accountId = feed.accountId,
        let feedId = feed.feedId
      else {
        completion([])
        return nil
      }
      return (accountId: accountId, feedId: feedId)
    }

    self.viewModel.fetchData(for: zipped) { results in
      completion(results)
    }
  }
}

struct FeedListEntry: TimelineEntry {
  let date: Date
  let items: [FeedWidgetItemResult]
}

struct FeedListView: View {
  @Environment(\.widgetFamily) var family
  let items: [FeedWidgetItemResult]
  let compressed: Bool
  let height: CGFloat

  fileprivate static let rowsForFamily = [
    WidgetFamily.systemSmall: 3,
    WidgetFamily.systemMedium: 3,
    WidgetFamily.systemLarge: 6
  ]

  var body: some View {
    let rows: CGFloat = CGFloat(Self.rowsForFamily[self.family]!)
    VStack(spacing: 0) {
      ForEach(self.items.startIndex ..< self.items.endIndex) { i in
        VStack(spacing: 0) {
          if i > 0 {
            Divider()
              .background(Color.gray)
          }
          FeedRowView(item: self.items[i], compressed: self.compressed)
            .frame(height: (self.height - (rows - 1)) / rows)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }
}

struct FeedListWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  var entry: FeedListProvider.Entry

  var body: some View {
    GeometryReader { metrics in
      HStack {
        Spacer(minLength: 0)
        FeedListView(
          items: entry.items,
          compressed: self.family == .systemSmall,
          height: metrics.size.height)
        Spacer(minLength: 0)
      }
      .frame(width: metrics.size.width)
    }
  }
}

struct FeedListWidget: Widget {
  var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: "FeedListWidget",
      intent: SelectFeedsIntent.self,
      provider: FeedListProvider()) { entry in
      FeedListWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Feed List Widget")
    .description("Display data from many of your EmonCMS feeds.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct FeedListWidget_Previews: PreviewProvider {
  static var previews: some View {
    let items = [
      FeedWidgetItem(
        accountId: "1",
        accountName: "Account",
        feedId: "1",
        feedName: "Use",
        feedChartData: [
          DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 3)
        ]),
      FeedWidgetItem(
        accountId: "1",
        accountName: "Account",
        feedId: "2",
        feedName: "Solar",
        feedChartData: [
          DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 123)
        ]),
      FeedWidgetItem(
        accountId: "1",
        accountName: "Account",
        feedId: "3",
        feedName: "HWT",
        feedChartData: [
          DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 9000)
        ]),
      FeedWidgetItem(
        accountId: "1",
        accountName: "Account",
        feedId: "4",
        feedName: "Use",
        feedChartData: [
          DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 3)
        ]),
      FeedWidgetItem(
        accountId: "1",
        accountName: "Account",
        feedId: "5",
        feedName: "Solar",
        feedChartData: [
          DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 123)
        ]),
      FeedWidgetItem(
        accountId: "1",
        accountName: "Account",
        feedId: "6",
        feedName: "HWT",
        feedChartData: [
          DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 0),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 3),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: 2),
          DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 9000)
        ])
    ]

    ForEach([WidgetFamily.systemSmall, WidgetFamily.systemMedium, WidgetFamily.systemLarge]) { family in
      let rows = FeedListView.rowsForFamily[family]!
      let entry = FeedListEntry(
        date: Date(),
        items: Array(items[0 ..< rows]).map { FeedWidgetItemResult.success($0) })
      FeedListWidgetEntryView(entry: entry)
        .previewContext(WidgetPreviewContext(family: family))
    }

    FeedListWidgetEntryView(
      entry: FeedListEntry(
        date: Date(),
        items: [
          FeedWidgetItemResult.failure(.fetchFailed(.fetchFailed)),
          FeedWidgetItemResult.failure(.fetchFailed(.fetchFailed)),
          FeedWidgetItemResult.failure(.fetchFailed(.fetchFailed))
        ]))
      .previewContext(WidgetPreviewContext(family: WidgetFamily.systemMedium))

    FeedListWidgetEntryView(
      entry: FeedListEntry(
        date: Date(),
        items: [
          FeedWidgetItemResult.failure(.fetchFailed(.fetchFailed)),
          FeedWidgetItemResult.failure(.noFeedInfo),
          FeedWidgetItemResult.failure(.unknown)
        ]))
      .previewContext(WidgetPreviewContext(family: WidgetFamily.systemMedium))
  }
}

extension WidgetFamily: Identifiable {
  public var id: String {
    return self.description
  }
}
