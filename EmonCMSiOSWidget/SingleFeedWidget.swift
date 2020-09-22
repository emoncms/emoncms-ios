//
//  SingleFeedWidget.swift
//  EmonCMSiOSWidget
//
//  Created by Matt Galloway on 19/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import SwiftUI
import WidgetKit

struct SingleFeedProvider: IntentTimelineProvider {
  private let viewModel: FeedViewModel

  init() {
    let dataDirectory = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.SharedApplicationGroupIdentifier)!
    let realmController = RealmController(dataDirectory: dataDirectory)
    let requestProvider = NSURLSessionHTTPRequestProvider()
    let api = EmonCMSAPI(requestProvider: requestProvider)
    self.viewModel = FeedViewModel(realmController: realmController, api: api)
  }

  func placeholder(in context: Context) -> SingleFeedEntry {
    let item = FeedWidgetItem(
      accountId: "1",
      accountName: "---",
      feedId: "1",
      feedName: "---",
      feedChartData: [])
    return SingleFeedEntry(date: Date(), item: item)
  }

  func getSnapshot(
    for configuration: SelectFeedIntent,
    in context: Context,
    completion: @escaping (SingleFeedEntry) -> Void) {
    self.fetchData(for: configuration, in: context) { item in
      let entry = SingleFeedEntry(date: Date(), item: item)
      completion(entry)
    }
  }

  func getTimeline(
    for configuration: SelectFeedIntent,
    in context: Context,
    completion: @escaping (Timeline<SingleFeedEntry>) -> Void) {
    self.fetchData(for: configuration, in: context) { item in
      let entry = SingleFeedEntry(date: Date(), item: item)
      let expiry = Calendar.current.date(byAdding: .minute, value: 2, to: Date()) ?? Date()
      let timeline = Timeline(entries: [entry], policy: .after(expiry))
      completion(timeline)
    }
  }

  private func fetchData(
    for configuration: SelectFeedIntent,
    in context: Context,
    completion: @escaping (FeedWidgetItem?) -> Void) {
    guard
      let accountId = configuration.feed?.accountId,
      let feedId = configuration.feed?.feedId
    else {
      completion(nil)
      return
    }

    self.viewModel.fetchData(accountId: accountId, feedId: feedId) { item, _ in
      completion(item)
    }
  }
}

struct SingleFeedEntry: TimelineEntry {
  let date: Date
  let item: FeedWidgetItem?
}

struct SingleFeedWidgetEntryView: View {
  var entry: SingleFeedProvider.Entry

  var body: some View {
    if let item = self.entry.item {
      SingleFeedView(item: item)
    } else {
      Text("Error")
    }
  }
}

struct SingleFeedWidget: Widget {
  var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: "SingleFeedWidget",
      intent: SelectFeedIntent.self,
      provider: SingleFeedProvider()) { entry in
      SingleFeedWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Feed Widget")
    .description("Display data from a single EmonCMS feed.")
    .supportedFamilies([.systemSmall])
  }
}

struct SingleFeedWidget_Previews: PreviewProvider {
  static var previews: some View {
    let item = FeedWidgetItem(
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
      ])
    let entry = SingleFeedEntry(date: Date(), item: item)

    SingleFeedWidgetEntryView(entry: entry)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
