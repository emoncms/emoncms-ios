//
//  Feed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class Feed: Object {
  @objc dynamic var id: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var tag: String = ""
  @objc dynamic var time: Date = Date()
  @objc dynamic var value: Double = 0
  @objc private dynamic var widgetChartPointsJson: Data?

  var widgetChartPoints: [DataPoint<Double>] {
    get {
      var dataPoints: [DataPoint<Double>] = []
      guard let dataJson = self.widgetChartPointsJson else {
        return dataPoints
      }
      do {
        if let data = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [[Double]] {
          for d in data {
            dataPoints.append(DataPoint<Double>(time: Date(timeIntervalSince1970: d[0]), value: d[1]))
          }
          return dataPoints
        }
      } catch {}
      return dataPoints
    }

    set {
      do {
        var toSerialise: [[Double]] = []
        for dataPoint in newValue {
          toSerialise.append([dataPoint.time.timeIntervalSince1970, dataPoint.value])
        }
        let data = try JSONSerialization.data(withJSONObject: toSerialise, options: [])
        self.widgetChartPointsJson = data
      } catch {
        self.widgetChartPointsJson = nil
      }
    }
  }

  override class func primaryKey() -> String? {
    return "id"
  }

  override class func ignoredProperties() -> [String] {
    return ["widgetChartPoints"]
  }
}

extension Feed {
  static func from(json: [String: Any]) -> Feed? {
    guard let id = json["id"] as? String else { return nil }
    guard let name = json["name"] as? String else { return nil }
    guard let tag = json["tag"] as? String else { return nil }
    guard let timeAny = json["time"],
      let timeDouble = Double.from(timeAny) else { return nil }
    guard let valueAny = json["value"],
      let value = Double.from(valueAny) else { return nil }

    let time = Date(timeIntervalSince1970: timeDouble)

    let feed = Feed()
    feed.id = id
    feed.name = name
    feed.tag = tag
    feed.time = time
    feed.value = value

    return feed
  }
}
