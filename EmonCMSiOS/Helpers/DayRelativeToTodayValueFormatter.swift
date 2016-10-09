//
//  DayRelativeToTodayValueFormatter.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 09/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Charts

class DayRelativeToTodayValueFormatter: NSObject, IAxisValueFormatter {

  private let dateFormatter: DateFormatter

  static let posixLocale = Locale(identifier: "en_US_POSIX")

  override init() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "eeeee"
    self.dateFormatter = dateFormatter

    super.init()
  }

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    let date = Date(timeIntervalSinceNow: value * 86400)
    return self.dateFormatter.string(from: date)
  }
  
}
