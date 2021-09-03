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
    let dataDirectory = DataController.sharedDataDirectory
    let realmController = RealmController(dataDirectory: dataDirectory)
    let requestProvider = NSURLSessionHTTPRequestProvider()
    let api = EmonCMSAPI(requestProvider: requestProvider)
    self.viewModel = FeedViewModel(realmController: realmController, api: api)
  }

  func placeholder(in context: Context) -> FeedListEntry {
    let rows = FeedListView.rowsForFamily[context.family]!
    let items = (0 ..< rows).map { _ in FeedWidgetItemResult.success(FeedWidgetItem.makePlaceholder()) }
    return FeedListEntry(date: Date(), items: items)
  }

  func getSnapshot(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping (FeedListEntry) -> Void)
  {
    self.fetchData(for: configuration, in: context) { results in
      let entry = FeedListEntry(date: Date(), items: results)
      completion(entry)
    }
  }

  func getTimeline(
    for configuration: SelectFeedsIntent,
    in context: Context,
    completion: @escaping (Timeline<FeedListEntry>) -> Void)
  {
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
    completion: @escaping ([FeedWidgetItemResult]) -> Void)
  {
    let rowCount = FeedListView.rowsForFamily[context.family]!

    guard !context.isPreview else {
      let items = (0 ..< rowCount).map { _ in FeedWidgetItemResult.success(FeedWidgetItem.makePlaceholder()) }
      completion(items)
      return
    }

    guard let feeds = configuration.feeds else {
      completion(Array(repeating: FeedWidgetItemResult.failure(.noFeedInfo), count: rowCount))
      return
    }

    let zipped = feeds.compactMap { feed -> (accountId: String, feedId: String)? in
      guard
        let accountId = feed.accountId,
        let feedId = feed.feedId
      else {
        completion(Array(repeating: FeedWidgetItemResult.failure(.noFeedInfo), count: rowCount))
        return nil
      }
      return (accountId: accountId, feedId: feedId)
    }

    self.viewModel.fetchData(for: zipped) { results in
      var allResults = results
      if allResults.count < rowCount {
        allResults += Array(repeating: FeedWidgetItemResult.failure(.noFeedInfo), count: rowCount - allResults.count)
      }
      completion(allResults)
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
    let rows = CGFloat(Self.rowsForFamily[self.family]!)
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
  @Environment(\.colorScheme) var colorScheme

  var entry: FeedListProvider.Entry

  var body: some View {
    ZStack {
      self.background
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

  private var background: some View {
    self.colorScheme == .dark ? Color(white: 0.15) : Color.white
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
    let items = (0 ..< 6).map { _ in FeedWidgetItem.makePlaceholder() }

    Group {
      ForEach([WidgetFamily.systemSmall, WidgetFamily.systemMedium, WidgetFamily.systemLarge]) { family in
        let rows = FeedListView.rowsForFamily[family]!
        let entry = FeedListEntry(
          date: Date(),
          items: Array(items[0 ..< rows]).map { FeedWidgetItemResult.success($0) })
        FeedListWidgetEntryView(entry: entry)
          .previewContext(WidgetPreviewContext(family: family))
          .environment(\.colorScheme, .light)
      }
    }

    Group {
      ForEach([WidgetFamily.systemSmall, WidgetFamily.systemMedium, WidgetFamily.systemLarge]) { family in
        let rows = FeedListView.rowsForFamily[family]!
        let entry = FeedListEntry(
          date: Date(),
          items: Array(items[0 ..< rows]).map { FeedWidgetItemResult.success($0) })
        FeedListWidgetEntryView(entry: entry)
          .previewContext(WidgetPreviewContext(family: family))
          .environment(\.colorScheme, .dark)
      }
    }

    ForEach([WidgetFamily.systemSmall, WidgetFamily.systemMedium, WidgetFamily.systemLarge]) { family in
      let rows = FeedListView.rowsForFamily[family]!
      let entry = FeedListEntry(
        date: Date(),
        items: Array(items[0 ..< rows]).map { _ in FeedWidgetItemResult.success(FeedWidgetItem(
          accountId: "1",
          accountName: "Account",
          feedId: "1",
          feedName: "Use",
          feedChartData: [])) })
      FeedListWidgetEntryView(entry: entry)
        .previewContext(WidgetPreviewContext(family: family))
    }

    FeedListWidgetEntryView(
      entry: FeedListEntry(
        date: Date(),
        items: [
          FeedWidgetItemResult.failure(.fetchFailed(.keychainLocked)),
          FeedWidgetItemResult.failure(.fetchFailed(.keychainLocked)),
          FeedWidgetItemResult.failure(.fetchFailed(.keychainLocked))
        ]))
      .previewContext(WidgetPreviewContext(family: WidgetFamily.systemMedium))

    FeedListWidgetEntryView(
      entry: FeedListEntry(
        date: Date(),
        items: [
          FeedWidgetItemResult.failure(.fetchFailed(.keychainLocked)),
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
