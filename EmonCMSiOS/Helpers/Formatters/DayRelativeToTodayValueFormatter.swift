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
  private let relativeTo: Date?

  static let posixLocale = Locale(identifier: "en_US_POSIX")

  init(relativeTo: Date?) {
    self.relativeTo = relativeTo
    let dateFormatter = DateFormatter()
    self.dateFormatter = dateFormatter

    super.init()
  }

  override convenience init() {
    self.init(relativeTo: nil)
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

    let timeAdd = value * 86_400
    let date: Date
    if let relativeTo = self.relativeTo {
      date = relativeTo.addingTimeInterval(timeAdd)
    } else {
      date = Date(timeIntervalSinceNow: timeAdd)
    }
    return self.dateFormatter.string(from: date)
  }
  
}
