//
//  ChartDataSet.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 20/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class ChartDataSet: Object {

  dynamic var uuid: String = UUID().uuidString
  private let charts = LinkingObjects(fromType: Chart.self, property: "dataSets")
  dynamic var chart: Chart { return self.charts.first! }
  dynamic var feed: Feed?

  override class func primaryKey() -> String? {
    return "uuid"
  }

}
