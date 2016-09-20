//
//  Chart.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 20/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

class Chart: Object {

  dynamic var uuid: String = UUID().uuidString
  dynamic var name: String = ""
  dynamic var feed: String = ""

  override class func primaryKey() -> String? {
    return "uuid"
  }

  private dynamic var dateRangeRaw: Int = 0
  private dynamic var startDate: Date = Date()
  private dynamic var endDate: Date = Date() - (60 * 60)
  private dynamic var dateInterval: TimeInterval = 0
  var dateRange: DateRange {
    get {
      switch self.dateRangeRaw {
      case 1:
        return .relative(self.endDate, self.dateInterval)
      case 2:
        return .relativeToNow(self.dateInterval)
      /*case 0:*/
      default:
        return .absolute(self.startDate, self.endDate)
      }
    }
    set {
      switch newValue {
      case .absolute(let startDate, let endDate):
        self.startDate = startDate
        self.endDate = endDate
      case .relative(let endDate, let dateInterval):
        self.endDate = endDate
        self.dateInterval = dateInterval
      case .relativeToNow(let dateInterval):
        self.dateInterval = dateInterval
      }
    }
  }

}
