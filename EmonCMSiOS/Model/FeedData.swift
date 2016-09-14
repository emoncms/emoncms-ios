//
//  FeedData.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

struct FeedDataPoint {

  let time: Date
  let value: Double

}

extension FeedDataPoint {

  static func from(dataArray: [Double]) -> FeedDataPoint? {
    guard dataArray.count == 2 else { return nil }

    let time = Date(timeIntervalSince1970: Double(dataArray[0]) / 1000)
    let value = Double(dataArray[1])

    return FeedDataPoint(time: time, value: value)
  }

}
