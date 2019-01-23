//
//  ChartXAxisDateFormatter.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Charts

final class ChartDateValueFormatter: NSObject, IAxisValueFormatter {

  enum FormatType {
    case auto
    case format(String)
    case formatter(DateFormatter)
  }

  private let dateFormatter: DateFormatter
  private let autoUpdateFormat: Bool
  var timeZone: TimeZone {
    get {
      return dateFormatter.timeZone
    }
    set {
      dateFormatter.timeZone = newValue
    }
  }

  static let posixLocale = Locale(identifier: "en_US_POSIX")

  private var dateRange: TimeInterval? {
    didSet {
      if oldValue != dateRange {
        self.updateAutoFormat()
      }
    }
  }

  init(_ type: FormatType) {
    let dateFormatter: DateFormatter
    switch type {
    case .auto:
      dateFormatter = DateFormatter()
      self.autoUpdateFormat = true
    case .format(let formatString):
      dateFormatter = DateFormatter()
      dateFormatter.locale = ChartDateValueFormatter.posixLocale
      dateFormatter.dateFormat = formatString
      self.autoUpdateFormat = false
    case .formatter(let formatter):
      dateFormatter = formatter
      self.autoUpdateFormat = false
    }
    self.dateFormatter = dateFormatter

    super.init()
  }

  convenience override init() {
    self.init(.auto)
  }

  private func updateAutoFormat() {
    guard self.autoUpdateFormat else { return }

    let range = self.dateRange ?? 0

    if range < 86400 {
      dateFormatter.timeStyle = .short
      dateFormatter.dateStyle = .none
    } else {
      dateFormatter.timeStyle = .none
      dateFormatter.dateStyle = .short
    }
  }

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    self.dateRange = axis?.axisRange
    let date = Date(timeIntervalSince1970: value)
    return self.dateFormatter.string(from: date)
  }

}
