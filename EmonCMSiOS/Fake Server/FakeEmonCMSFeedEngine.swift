//
//  FakeEmonCMSFeedEngine.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 21/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

final class FakeEmonCMSFeedEngine {

  typealias FeedMeta = (interval: TimeInterval, startTime: TimeInterval?)
  typealias DataPoint = (time: TimeInterval, value: Double?)

  final class FeedStorage {
    let interval: TimeInterval
    var startTime: TimeInterval? = nil
    var data: [DataPoint] = []

    init(interval: TimeInterval) {
      self.interval = interval
    }
  }

  private var feedDatabase = [String:FeedStorage]()

  func create(id: String, interval: TimeInterval) {
    self.feedDatabase[id] = FeedStorage(interval: interval)
  }

  func delete(id: String) {
    self.feedDatabase[id] = nil
  }

  func getMeta(id: String) -> FeedMeta? {
    guard let feedStorage = self.feedDatabase[id] else { return nil }
    return FeedMeta(interval: feedStorage.interval, startTime: feedStorage.startTime)
  }

  func nPoints(id: String) -> Int? {
    guard let feedStorage = self.feedDatabase[id] else { return nil }
    return feedStorage.data.count
  }

  func post(id: String, time: TimeInterval, value: Double) {
    guard let feedStorage = self.feedDatabase[id] else { return }

    let interval = feedStorage.interval
    let bucketedTime = floor(time / interval) * interval

    let padding: Int
    if let startTime = feedStorage.startTime {
      guard startTime < bucketedTime else { return }
      padding = Int(floor((bucketedTime - startTime) / interval)) - 1
    } else {
      feedStorage.startTime = time
      padding = 0
    }

    func writePoint(time: TimeInterval, value: Double?) {
      let point = DataPoint(time: time * 1000.0, value: value)
      feedStorage.data.append(point)
    }

    if padding > 0 {
      guard let lastTime = feedStorage.data.last?.time else { return }

      var pointTime = lastTime + interval
      while pointTime < bucketedTime {
        writePoint(time: pointTime, value: nil)
        pointTime += interval
      }
    }

    writePoint(time: bucketedTime, value: value)
  }

  func update(id: String, time: TimeInterval, value: Double) {
    guard
      let feedStorage = self.feedDatabase[id],
      let startTime = feedStorage.startTime
      else { return }

    let interval = feedStorage.interval
    let bucketedTime = floor(time / interval) * interval
    let bucket = Int((bucketedTime - startTime) / interval)

    guard bucket < feedStorage.data.count else {
      self.post(id: id, time: time, value: value)
      return
    }

    feedStorage.data[bucket] = (time: bucketedTime, value: value)
  }

  func lastValue(id: String) -> DataPoint? {
    return self.feedDatabase[id]?.data.last
  }

  func getData(id: String, start: TimeInterval, end: TimeInterval, interval: Int) -> [DataPoint] {
    guard
      let feedStorage = self.feedDatabase[id],
      let startTime = feedStorage.startTime
      else { return [] }
    guard start < end else { return [] }
    guard interval > 0 else { return [] }

    let feedInterval = feedStorage.interval
    let startSecs = start / 1000.0
    let endSecs = end / 1000.0

    var points = [DataPoint]()
    var time: TimeInterval = 0
    var i = 0
    while time < endSecs {
      time = startSecs + Double(interval * i)

      let bucket = Int(round((time - startTime) / feedInterval))
      if bucket > 0 && bucket < feedStorage.data.count {
        let feedValue = feedStorage.data[bucket]
        points.append(feedValue)
      }

      i += 1
    }

    return points
  }

}
