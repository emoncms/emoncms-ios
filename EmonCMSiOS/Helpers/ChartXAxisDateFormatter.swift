//
//  ChartXAxisDateFormatter.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Charts

class ChartXAxisDateFormatter: ChartXAxisValueFormatter {

  private let dateFormatter: DateFormatter

  static let posixLocale = Locale(identifier: "en_US_POSIX")

  init(dateFormatter: DateFormatter) {
    self.dateFormatter = dateFormatter
  }

  convenience init(formatString: String) {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = ChartXAxisDateFormatter.posixLocale
    dateFormatter.dateFormat = formatString
    self.init(dateFormatter: dateFormatter)
  }

  convenience init() {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    dateFormatter.dateStyle = .none
    self.init(dateFormatter: dateFormatter)
  }

  func stringForXValue(_ index: Int, original: String, viewPortHandler: ChartViewPortHandler) -> String {
    guard let time = Double(original) else {
      return original
    }

    let date = Date(timeIntervalSince1970: time)
    return self.dateFormatter.string(from: date)
  }

}
