//
//  DayRelativeToTodayValueFormatter.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 09/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Charts

final class DayRelativeToTodayValueFormatter: NSObject, IAxisValueFormatter {

  private let dateFormatter: DateFormatter

  static let posixLocale = Locale(identifier: "en_US_POSIX")

  override init() {
    let dateFormatter = DateFormatter()
    self.dateFormatter = dateFormatter

    super.init()
  }

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    let range = axis?.axisRange ?? 0

    switch range {
    case let x where x <= 14:
      self.dateFormatter.dateFormat = "eeeee"
    case let x where x > 14 && x <= 31:
      self.dateFormatter.dateFormat = "dd"
    default:
      self.dateFormatter.dateFormat = "MMM dd"
    }

    let date = Date(timeIntervalSinceNow: value * 86400)
    return self.dateFormatter.string(from: date)
  }
  
}
