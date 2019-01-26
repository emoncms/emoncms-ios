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

    if range < 86_400 { //< 1 day
      dateFormatter.dateFormat = "h:mm a"
    } else {
      dateFormatter.dateFormat = nil
      dateFormatter.timeStyle = .none
      dateFormatter.dateStyle = .short
    }
  }

  func stringForValue(_ value: Double, axis: AxisBase?) -> String {
    self.dateRange = axis?.axisRange
    let date = Date(timeIntervalSince1970: value)
    var string = self.dateFormatter.string(from: date)

    if self.autoUpdateFormat {
      let range = self.dateRange ?? 0
      if range > 86_400 {
        let components = string.split(separator: "/")
        if components.count == 3 {
          if range < 31_536_000 { //< 1 year
            string = components[0...1].joined(separator: "/")
          }
        }
      }
    }

    return string
  }

}
