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
    return FeedListEntry(date: Date(), items: [])
  }

  func getSnapshot(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping (FeedListEntry) -> Void) {
    self.fetchData(for: configuration, in: context) { items in
      let entry = FeedListEntry(date: Date(), items: items)
      completion(entry)
    }
  }

  func getTimeline(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping (Timeline<FeedListEntry>) -> Void) {
    self.fetchData(for: configuration, in: context) { items in
      let entry = FeedListEntry(date: Date(), items: items)
      let expiry = Calendar.current.date(byAdding: .minute, value: 2, to: Date()) ?? Date()
      let timeline = Timeline(entries: [entry], policy: .after(expiry))
      completion(timeline)
    }
  }

  private func fetchData(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping ([FeedWidgetItem]) -> Void) {
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
    self.viewModel.fetchData(for: zipped) { items, _ in
      completion(items)
    }
  }
}

struct FeedListEntry: TimelineEntry {
  let date: Date
  let items: [FeedWidgetItem]
}

struct FeedListView: View {
  @Environment(\.widgetFamily) var family
  let items: [FeedWidgetItem]
  let compressed: Bool
  let height: CGFloat

  private static let rowsForFamily = [
    WidgetFamily.systemSmall: 3,
    WidgetFamily.systemMedium: 3,
    WidgetFamily.systemLarge: 6
  ]

  var body: some View {
    let rows: CGFloat = CGFloat(Self.rowsForFamily[self.family]!)
    VStack(spacing: 0) {
      ForEach(self.items) { item in
        VStack(spacing: 0) {
          FeedRowView(item: item, compressed: self.compressed)
            .frame(minHeight: (self.height - (rows - 1)) / rows)
          Divider()
            .background(Color.gray)
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
      FeedListView(
        items: entry.items,
        compressed: self.family == .systemSmall,
        height: metrics.size.height)
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
    .description("Display data from up to 3 of your EmonCMS feeds.")
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
        ])
    ]
    let entry = FeedListEntry(date: Date(), items: items)

    FeedListWidgetEntryView(entry: entry)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
    FeedListWidgetEntryView(entry: entry)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
    FeedListWidgetEntryView(entry: entry)
      .previewContext(WidgetPreviewContext(family: .systemLarge))
  }
}
