//
//  FeedRowView.swift
//  EmonCMSiOSWidgetExtension
//
//  Created by Matt Galloway on 19/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import SwiftUI
import WidgetKit

struct FeedRowView: View {
  let item: FeedWidgetItemResult
  let compressed: Bool

  public var body: some View {
    switch self.item {
    case .success(let item):
      successBody(item: item)
    case .failure(let error):
      failureBody(error: error)
    }
  }

  private func successBody(item: FeedWidgetItem) -> some View {
    GeometryReader { metrics in
      Link(destination: URL(string: "emoncms://feed?accountId=\(item.accountId)&feedId=\(item.feedId)")!) {
        HStack(spacing: 0) {
          // Feed name & account name
          VStack(alignment: .leading) {
            Text(item.feedName)
              .font(.caption)
              .fontWeight(.bold)
              .minimumScaleFactor(0.7)
              .lineLimit(1)
            Text(item.accountName)
              .font(.caption2)
              .fontWeight(.regular)
              .foregroundColor(Color.gray)
              .minimumScaleFactor(0.7)
              .lineLimit(1)
          }
          .padding(.leading, 8)
          .padding(.trailing, 4)
          .padding(.vertical, 4)
          .frame(width: metrics.size.width * 0.6, alignment: .leading)
          .frame(minHeight: metrics.size.height)

          // Chart
          if !self.compressed {
            FeedChartView(data: item.feedChartData)
              .color(Color(EmonCMSColors.Chart.Blue))
              .lineWidth(2)
              .padding(.vertical, 12)
              .padding(.horizontal, 4)
              .frame(width: metrics.size.width * 0.2, alignment: .trailing)
              .frame(minHeight: metrics.size.height)
          }

          // Feed value
          Text(item.feedChartData.last?.value.prettyFormat() ?? "---")
            .font(.caption)
            .fontWeight(.bold)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.leading, 4)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .frame(width: metrics.size.width * (self.compressed ? 0.4 : 0.2), alignment: .trailing)
            .frame(minHeight: metrics.size.height)
        }.frame(minHeight: metrics.size.height)
      }
    }
  }

  private func failureBody(error: FeedWidgetItemError) -> some View {
    let errorText: String
    switch error {
    case .noFeedInfo, .unknown:
      errorText = "No feed"
    case .fetchFailed:
      errorText = "No connection"
    }

    return VStack {
      Text("Error loading data")
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

struct FeedRowView_Previews: PreviewProvider {
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
        DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 123)
      ])

    FeedRowView(item: .success(item), compressed: true)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
    FeedRowView(item: .success(item), compressed: false)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
