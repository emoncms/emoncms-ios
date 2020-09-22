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
  let item: FeedWidgetItem
  let compressed: Bool

  public var body: some View {
    GeometryReader { metrics in
      HStack(spacing: 0) {
        // Feed name & account name
        VStack(alignment: .leading) {
          Text(self.item.feedName)
            .font(.caption)
            .fontWeight(.bold)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
          Text(self.item.accountName)
            .font(.caption2)
            .fontWeight(.regular)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .frame(width: metrics.size.width * 0.5, alignment: .leading)
        .frame(minHeight: metrics.size.height)

        // Chart
        if !self.compressed {
          FeedChartView(data: self.item.feedChartData)
            .stroke(Color(EmonCMSColors.Chart.Blue), lineWidth: 2)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .frame(width: metrics.size.width * 0.3, alignment: .trailing)
            .frame(minHeight: metrics.size.height)
        }

        // Feed value
        Text(self.item.feedChartData.last?.value.prettyFormat() ?? "---")
          .font(.caption)
          .fontWeight(.bold)
          .minimumScaleFactor(0.5)
          .lineLimit(1)
          .padding(.leading, 4)
          .padding(.trailing, 8)
          .padding(.vertical, 4)
          .frame(width: metrics.size.width * (self.compressed ? 0.5 : 0.2), alignment: .trailing)
          .frame(minHeight: metrics.size.height)
      }.frame(minHeight: metrics.size.height)
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

    FeedRowView(item: item, compressed: true)
      .previewContext(WidgetPreviewContext(family: .systemSmall))
    FeedRowView(item: item, compressed: false)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
