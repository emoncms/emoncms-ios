//
//  DateRange.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 20/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

enum DateRange {

  case relative(DateComponents)
  case absolute(Date, Date)

  func calculateDates(relativeTo: Date = Date()) -> (Date, Date) {
    switch self {
    case .relative(let relative):
      let endDate = relativeTo

      let calendar = Calendar.current
      let startDate = calendar.date(byAdding: relative, to: endDate)!

      return (startDate, endDate)

    case .absolute(let startDate, let endDate):
      return (startDate, endDate)
    }
  }

  static func relative(config: (inout DateComponents) -> Void) -> DateRange {
    var dateComponents = DateComponents()
    config(&dateComponents)
    return .relative(dateComponents)
  }

  static func from1h8hDMYSegmentedControlIndex(_ index: Int) -> DateRange {
    var dateComponents = DateComponents()
    switch index {
    case 0:
      dateComponents.hour = -1
    case 1:
      dateComponents.hour = -8
    case 2:
      dateComponents.day = -1
    case 3:
      dateComponents.month = -1
    case 4:
      dateComponents.year = -1
    default:
      dateComponents.hour = -8
    }
    return .relative(dateComponents)
  }

  static func to1h8hDMYSegmentedControlIndex(_ dateComponents: DateComponents) -> Int? {
    if dateComponents == DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: -1, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil) {
      return 0
    }
    if dateComponents == DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: -8, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil) {
      return 1
    }
    if dateComponents == DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: -1, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil) {
      return 2
    }
    if dateComponents == DateComponents(calendar: nil, timeZone: nil, era: nil, year: nil, month: -1, day: nil, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil) {
      return 3
    }
    if dateComponents == DateComponents(calendar: nil, timeZone: nil, era: nil, year: -1, month: nil, day: nil, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil) {
      return 4
    }
    return nil
  }

  static func fromWMYSegmentedControlIndex(_ index: Int) -> DateRange {
    var dateComponents = DateComponents()
    switch index {
    case 0:
      dateComponents.weekOfYear = -1
    case 1:
      dateComponents.month = -1
    case 2:
      dateComponents.year = -1
    default:
      dateComponents.month = -1
    }
    return .relative(dateComponents)
  }

}
