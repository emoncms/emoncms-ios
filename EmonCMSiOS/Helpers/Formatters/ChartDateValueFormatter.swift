//
//  ChartXAxisDateFormatter.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Charts

final class ChartDateValueFormatter: NSObject, AxisValueFormatter {
  enum FormatType {
    case auto
    case format(String)
    case formatter(DateFormatter)
  }

  private let dateFormatter: DateFormatter
  private let autoUpdateFormat: Bool
  var timeZone: TimeZone {
    get {
      return self.dateFormatter.timeZone
    }
    set {
      self.dateFormatter.timeZone = newValue
    }
  }

  static let posixLocale = Locale(identifier: "en_US_POSIX")

  private var dateRange: TimeInterval? {
    didSet {
      if oldValue != self.dateRange {
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

  override convenience init() {
    self.init(.auto)
  }

  private func updateAutoFormat() {
    guard self.autoUpdateFormat else { return }

    let range = self.dateRange ?? 0

    if range < 86400 { // < 1 day
      self.dateFormatter.dateFormat = nil
      self.dateFormatter.timeStyle = .short
      self.dateFormatter.dateStyle = .none
    } else {
      self.dateFormatter.dateFormat = nil
      self.dateFormatter.timeStyle = .none
      self.dateFormatter.dateStyle = .short
    }
  }

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    self.dateRange = axis?.axisRange
    let date = Date(timeIntervalSince1970: value)
    var string = self.dateFormatter.string(from: date)

    if self.autoUpdateFormat {
      let range = self.dateRange ?? 0
      if range > 86400 {
        let components = string.split(separator: "/")
        if components.count == 3 {
          if range < 31536000 { // < 1 year
            string = components[0 ... 1].joined(separator: "/")
          }
        }
      }
    }

    return string
  }
}
