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
              .fontWeight(.bold)
            Text(item.accountName)
              .font(.caption)
              .fontWeight(.regular)
          }
          .padding(.leading, 12)
          .padding(.trailing, 12)
          .padding(.top, 12)

          Spacer()
        }

        // Chart
        FeedChartView(data: item.feedChartData)
          .stroke(Color(EmonCMSColors.Chart.Blue), lineWidth: 2)
          .padding(.vertical, 8)
          .padding(.horizontal, 12)

        // Feed value
        HStack(spacing: 0) {
          Spacer()
          Text(item.feedChartData.last?.value.prettyFormat() ?? "---")
            .font(.system(size: 40))
            .fontWeight(.semibold)
            .minimumScaleFactor(0.5)
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
        }
      }
    }
  }

  private func failureBody(error: FeedWidgetItemError) -> some View {
    VStack {
      Text("Error loading data")
        .font(.footnote)
        .fontWeight(.bold)
        .lineLimit(1)
      switch error {
      case .noFeedInfo, .unknown:
        Text("No feed")
          .font(.footnote)
          .fontWeight(.regular)
          .foregroundColor(Color.gray)
          .lineLimit(1)
      case .fetchFailed:
        Text("No connection")
          .font(.footnote)
          .fontWeight(.regular)
          .foregroundColor(Color.gray)
          .lineLimit(1)
      }
    }
  }
}

struct SingleFeedView_Previews: PreviewProvider {
  static var previews: some View {
    let item = FeedWidgetItem(
      accountId: "1",
      accountName: "Account",
      feedId: "1",
      feedName: "Use",
      feedChartData: [
        DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 8721),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1000),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 5678),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 9283),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: -1020),
        DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 1234)
      ])

    SingleFeedView(item: FeedWidgetItemResult.success(item))
      .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
