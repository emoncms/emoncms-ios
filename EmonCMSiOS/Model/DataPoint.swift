//
//  DataPoint.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

struct DataPoint {

  let time: Date
  let value: Double

}

extension DataPoint {

  static func from(json: [Any]) -> DataPoint? {
    guard json.count == 2 else { return nil }

    guard let timeDouble = Double.from(json[0]) else { return nil }
    guard let value = Double.from(json[1]) else { return nil }

    let time = Date(timeIntervalSince1970: timeDouble / 1000)

    return DataPoint(time: time, value: value)
  }

}
