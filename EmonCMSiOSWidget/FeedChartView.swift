//
//  FeedChartView.swift
//  EmonCMSiOSWidgetExtension
//
//  Created by Matt Galloway on 20/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Foundation
import SwiftUI
import WidgetKit

struct FeedChartView: View {
  let data: [DataPoint<Double>]

  private var color: Color = .black
  private var lineWidth: CGFloat = 1.0

  init(data: [DataPoint<Double>]) {
    self.data = data
  }

  var body: some View {
    let lighterColor = self.color.opacity(0.5)

    GeometryReader { metrics in
      ZStack {
        self.path(forSize: metrics.size, type: .fill)
          .fill(LinearGradient(gradient: Gradient(colors: [lighterColor, Color.clear]), startPoint: .top,
                               endPoint: .bottom))
        self.path(forSize: metrics.size, type: .line)
          .stroke(self.color, lineWidth: self.lineWidth)
      }
    }
  }

  private enum PathType {
    case line
    case fill
  }

  private func path(forSize size: CGSize, type: PathType) -> Path {
    guard
      let minTime = self.data.first?.time,
      let maxTime = self.data.last?.time
    else {
      return Path()
    }

    return Path { path in
      let timeRange = maxTime.timeIntervalSince(minTime)

      let (minValue, maxValue) = self.data
        .reduce(into: (Double.greatestFiniteMagnitude, -Double.greatestFiniteMagnitude)) { result, dataPoint in
          if dataPoint.value < result.0 {
            result.0 = dataPoint.value
          }
          if dataPoint.value > result.1 {
            result.1 = dataPoint.value
          }
        }
      let valueRange = maxValue - minValue

      let points = self.data.map { dataPoint -> CGPoint in
        let x = Double(size.width) * dataPoint.time.timeIntervalSince(minTime) / timeRange
        let y = Double(size.height) - (Double(size.height) * (dataPoint.value - minValue) / valueRange)
        return CGPoint(x: x, y: y)
      }

      switch type {
      case .fill:
        path.move(to: CGPoint(x: 0, y: size.height))
        points.forEach { path.addLine(to: $0) }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
      case .line:
        for (i, point) in points.enumerated() {
          if i == 0 {
            path.move(to: point)
          } else {
            path.addLine(to: point)
          }
        }
      }
    }
  }
}

extension FeedChartView {
  func color(_ color: Color) -> FeedChartView {
    var copy = self
    copy.color = color
    return copy
  }

  func lineWidth(_ lineWidth: CGFloat) -> FeedChartView {
    var copy = self
    copy.lineWidth = lineWidth
    return copy
  }
}

struct FeedChartView_Previews: PreviewProvider {
  static var previews: some View {
    FeedChartView(data: [
      DataPoint<Double>(time: Date(timeIntervalSince1970: 0), value: 8721),
      DataPoint<Double>(time: Date(timeIntervalSince1970: 1), value: 1000),
      DataPoint<Double>(time: Date(timeIntervalSince1970: 2), value: 5678),
      DataPoint<Double>(time: Date(timeIntervalSince1970: 3), value: 9283),
      DataPoint<Double>(time: Date(timeIntervalSince1970: 4), value: -1020),
      DataPoint<Double>(time: Date(timeIntervalSince1970: 5), value: 1234)
    ])
    .color(Color.blue)
    .lineWidth(2)
    .padding(12)
    .previewContext(WidgetPreviewContext(family: .systemSmall))
  }
}
