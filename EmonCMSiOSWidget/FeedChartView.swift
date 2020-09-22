//
//  FeedChartView.swift
//  EmonCMSiOSWidgetExtension
//
//  Created by Matt Galloway on 20/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Foundation
import SwiftUI

struct FeedChartView: Shape {
  let data: [DataPoint<Double>]

  func path(in rect: CGRect) -> Path {
    guard
      let minTime = self.data.first?.time,
      let maxTime = self.data.last?.time else {
      return Path()
    }

    let size = rect.size

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
      let point = CGPoint(x: x, y: y)
      return point
    }

    return Path { path in
      path.addLines(points)
    }
  }
}
