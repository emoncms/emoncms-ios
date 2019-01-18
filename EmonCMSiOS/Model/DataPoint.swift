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

extension DataPoint {

  static func merge(pointsFrom points: [[DataPoint]], mergeBlock: (TimeInterval, Date, [Double]) -> Void) {
    guard points.count > 0 else { return }
    var indices = points.map { $0.startIndex }
    var lastTime: Date?

    while true {
      let finished = indices.enumerated().reduce(false) { (result, item) in
        return result || (item.element >= points[item.offset].endIndex)
      }
      if finished { break }

      let thisPoints = points.enumerated().map { $0.element[indices[$0.offset]] }
      let thisTimes = thisPoints.map { $0.time }
      if Set(thisTimes).count > 1 {
        let (minimumIndex, _) = thisTimes.enumerated().reduce((-1, Date.distantFuture)) {
          ($0.1 < $1.1) ? $0 : $1
        }
        indices[minimumIndex] = indices[minimumIndex].advanced(by: 1)
        continue
      }

      guard let time = thisTimes.first else { continue }

      guard let unwrappedLastTime = lastTime else {
        lastTime = time
        continue
      }

      let timeDelta = time.timeIntervalSince(unwrappedLastTime)
      lastTime = time

      mergeBlock(timeDelta, time, thisPoints.map { $0.value })

      indices = indices.map { $0.advanced(by: 1) }
    }
  }

}
