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
    let item = FeedWidgetItem.placeholder
    return SingleFeedEntry(date: Date(), item: .success(item))
  }

  func getSnapshot(
    for configuration: SelectFeedIntent,
    in context: Context,
    completion: @escaping (SingleFeedEntry) -> Void) {
    self.fetchData(for: configuration, in: context) { result in
      let entry = SingleFeedEntry(date: Date(), item: result)
      completion(entry)
    }
  }

  func getTimeline(
    for configuration: SelectFeedIntent,
    in context: Context,
    completion: @escaping (Timeline<SingleFeedEntry>) -> Void) {
    self.fetchData(for: configuration, in: context) { result in
      let entry = SingleFeedEntry(date: Date(), item: result)
      let expiry = Calendar.current.date(byAdding: .minute, value: 2, to: Date()) ?? Date()
      let timeline = Timeline(entries: [entry], policy: .after(expiry))
      completion(timeline)
    }
  }

  private func fetchData(
    for configuration: SelectFeedIntent,
    in context: Context,
    completion: @escaping (FeedWidgetItemResult) -> Void) {
    guard !context.isPreview else {
      completion(.success(FeedWidgetItem.placeholder))
      return
    }

    guard
      let accountId = configuration.feed?.accountId,
      let feedId = configuration.feed?.feedId
    else {
      completion(.failure(.noFeedInfo))
      return
    }

    self.viewModel.fetchData(accountId: accountId, feedId: feedId) { result in
      completion(result)
    }
  }
}

struct SingleFeedEntry: TimelineEntry {
  let date: Date
  let item: FeedWidgetItemResult
}

struct SingleFeedWidgetEntryView: View {
  @Environment(\.colorScheme) var colorScheme

  var entry: SingleFeedProvider.Entry

  var body: some View {
    ZStack {
      self.background
      SingleFeedView(item: self.entry.item)
    }
  }

  private var background: some View {
    self.colorScheme == .dark ? Color(white: 0.15) : Color.white
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
    let item = FeedWidgetItem.placeholder
    let entry = SingleFeedEntry(date: Date(), item: .success(item))

    SingleFeedWidgetEntryView(entry: entry)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
      .environment(\.colorScheme, .light)

    SingleFeedWidgetEntryView(entry: entry)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
      .environment(\.colorScheme, .dark)
  }
}
