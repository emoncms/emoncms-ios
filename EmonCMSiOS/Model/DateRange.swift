//
//  DateRange.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 20/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

enum DateRange {
  case absolute(Date, Date)
  case relative(Date, TimeInterval)
  case relativeToNow(TimeInterval)

  func startDate() -> Date {
    switch self {
    case .absolute(let startDate, _):
      return startDate
    case .relative(let endDate, let interval):
      return endDate - interval
    case .relativeToNow(let interval):
      return Date() - interval
    }
  }

  func endDate() -> Date {
    switch self {
    case .absolute(_, let endDate):
      return endDate
    case .relative(let endDate, _):
      return endDate
    case .relativeToNow(_):
      return Date()
    }
  }
}
