//
//  SingleFeedView.swift
//  EmonCMSiOSWidgetExtension
//
//  Created by Matt Galloway on 20/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Foundation
import SwiftUI
import WidgetKit

struct SingleFeedView: View {
  let item: FeedWidgetItemResult

  public var body: some View {
    switch self.item {
    case .success(let item):
      successBody(item: item)
    case .failure(let error):
      failureBody(error: error)
    }
  }

  private func successBody(item: FeedWidgetItem) -> some View {
    GeometryReader { _ in
      VStack(spacing: 0) {
        // Feed name & account name
        HStack(spacing: 0) {
          VStack(alignment: .leading) {
            Text(item.feedName)
              .font(.footnote)
              .fontWeight(.semibold)
              .minimumScaleFactor(0.5)
            Text(item.accountName)
              .font(.caption)
              .fontWeight(.light)
              .minimumScaleFactor(0.5)
              .foregroundColor(Color.gray)
          }
          .padding(.leading, 16)
          .padding(.trailing, 16)
          .padding(.top, 14)

          Spacer()
        }

        // Chart
        FeedChartView(data: item.feedChartData)
          .color(Color(EmonCMSColors.Chart.Blue))
          .lineWidth(2)
          .padding(.vertical, 8)
          .padding(.horizontal, 0)

        // Feed value
        HStack(spacing: 0) {
          Spacer()
          Text(item.feedChartData.last?.value.prettyFormat() ?? "---")
            .font(.system(size: 40))
            .fontWeight(.regular)
            .minimumScaleFactor(0.5)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.bottom, 6)
        }
      }
    }
    .widgetURL(URL(string: "emoncms://feed?accountId=\(item.accountId)&feedId=\(item.feedId)")!)
  }

  private func failureBody(error: FeedWidgetItemError) -> some View {
    let titleText: String
    let errorText: String
    switch error {
    case .noFeedInfo, .unknown:
      titleText = "No feed"
      errorText = "Select a feed"
    case .fetchFailed:
      titleText = "Error loading data"
      errorText = "No connection"
    }

    return VStack {
      Text(titleText)
        .font(.footnote)
        .fontWeight(.bold)
        .lineLimit(1)
      Text(errorText)
        .font(.footnote)
        .fontWeight(.regular)
        .foregroundColor(Color.gray)
        .lineLimit(1)
    }
  }
}

struct SingleFeedView_Previews: PreviewProvider {
  static var previews: some View {
    let item = FeedWidgetItem.placeholder

    SingleFeedView(item: FeedWidgetItemResult.success(item))
      .previewContext(WidgetPreviewContext(family: .systemSmall))

    SingleFeedView(item: FeedWidgetItemResult.failure(.noFeedInfo))
      .previewContext(WidgetPreviewContext(family: .systemSmall))

    SingleFeedView(item: FeedWidgetItemResult.failure(.fetchFailed(.invalidFeed)))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
