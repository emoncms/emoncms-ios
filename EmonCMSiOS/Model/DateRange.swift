//
//  DateRange.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 20/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

enum DateRange {
  enum RelativeTime: Int {
    case hour1
    case hour8
    case day
    case month
    case year
  }

  case relative(RelativeTime)
  case absolute(Date, Date)

  func calculateDates(relativeTo: Date = Date()) -> (Date, Date) {
    switch self {
    case .relative(let relative):
      let endDate = relativeTo

      var dateComponents = DateComponents()
      switch relative {
      case .hour1:
        dateComponents.hour = -1
      case .hour8:
        dateComponents.hour = -8
      case .day:
        dateComponents.day = -1
      case .month:
        dateComponents.month = -1
      case .year:
        dateComponents.year = -1
      }

      let calendar = Calendar.current
      let startDate = calendar.date(byAdding: dateComponents, to: endDate)!

      return (startDate, endDate)

    case .absolute(let startDate, let endDate):
      return (startDate, endDate)
    }
  }
}
