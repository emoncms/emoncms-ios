//
//  Chart.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 21/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class Chart: Object {

  dynamic var uuid: String = UUID().uuidString
  dynamic var name: String = ""
  let dataSets = List<ChartDataSet>()

  override class func primaryKey() -> String? {
    return "uuid"
  }

  private dynamic var dateRangeRaw: Int = 1
  private dynamic var startDate: Date = Date()
  private dynamic var endDate: Date = Date()
  private dynamic var relativeTime: Int = 1
  var dateRange: DateRange {
    get {
      switch self.dateRangeRaw {
      case 1:
        return .relative(DateRange.RelativeTime(rawValue: self.relativeTime) ?? .hour1)
        /*case 0:*/
      default:
        return .absolute(self.startDate, self.endDate)
      }
    }
    set {
      switch newValue {
      case .relative(let relativeTime):
        self.relativeTime = relativeTime.rawValue
      case .absolute(let startDate, let endDate):
        self.startDate = startDate
        self.endDate = endDate
      }
    }
  }

}
