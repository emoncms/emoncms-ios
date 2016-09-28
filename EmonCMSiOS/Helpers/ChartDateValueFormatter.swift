//
//  ChartXAxisDateFormatter.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Charts

class ChartDateValueFormatter: NSObject, IAxisValueFormatter {

  private let dateFormatter: DateFormatter

  static let posixLocale = Locale(identifier: "en_US_POSIX")

  init(dateFormatter: DateFormatter) {
    self.dateFormatter = dateFormatter
    super.init()
  }

  convenience init(formatString: String) {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = ChartDateValueFormatter.posixLocale
    dateFormatter.dateFormat = formatString
    self.init(dateFormatter: dateFormatter)
  }

  convenience override init() {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    dateFormatter.dateStyle = .none
    self.init(dateFormatter: dateFormatter)
  }

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    let date = Date(timeIntervalSince1970: value)
    return self.dateFormatter.string(from: date)
  }

}
