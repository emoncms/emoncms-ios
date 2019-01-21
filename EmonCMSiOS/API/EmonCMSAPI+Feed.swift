//
//  EmonCMSAPI+Feed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 21/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

extension EmonCMSAPI {

  func feedList(_ account: AccountCredentials) -> Observable<[Feed]> {
    return self.request(account, path: "feed/list").map { resultData -> [Feed] in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
        let json = anyJson as? [Any] else {
          throw EmonCMSAPIError.invalidResponse
      }

      var feeds: [Feed] = []
      for i in json {
        if let feedJson = i as? [String:Any],
          let feed = Feed.from(json: feedJson) {
          feeds.append(feed)
        }
      }

      return feeds
    }
  }

  func feedFields(_ account: AccountCredentials, id: String) -> Observable<Feed> {
    let queryItems = [
      "id": id
    ]

    return self.request(account, path: "feed/aget", queryItems: queryItems).map { resultData -> Feed in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
        let json = anyJson as? [String: Any],
        let feed = Feed.from(json: json) else {
          throw EmonCMSAPIError.invalidResponse
      }

      return feed
    }
  }

  func feedField(_ account: AccountCredentials, id: String, fieldName: String) -> Observable<String> {
    let queryItems = [
      "id": id,
      "field": fieldName
    ]

    return self.request(account, path: "feed/get", queryItems: queryItems).map { resultData -> String in
      guard let json = try? JSONSerialization.jsonObject(with: resultData, options: [.allowFragments]),
        let value = json as? String else {
          throw EmonCMSAPIError.invalidResponse
      }

      return value
    }
  }

  private static func dataPoints(fromJsonData data: Data) throws -> [DataPoint] {
    guard let json = try? JSONSerialization.jsonObject(with: data),
      let dataPointsJson = json as? [Any] else {
        throw EmonCMSAPIError.invalidResponse
    }

    var dataPoints: [DataPoint] = []
    for dataPointJson in dataPointsJson {
      guard let typedDataPoint = dataPointJson as? [Double] else {
        continue
      }
      if let dataPoint = DataPoint.from(json: typedDataPoint) {
        dataPoints.append(dataPoint)
      }
    }
    return dataPoints
  }

  func feedData(_ account: AccountCredentials, id: String, at startTime: Date, until endTime: Date, interval: Int) -> Observable<[DataPoint]> {
    let queryItems = [
      "id": id,
      "start": "\(UInt64(startTime.timeIntervalSince1970 * 1000))",
      "end": "\(UInt64(endTime.timeIntervalSince1970 * 1000))",
      "interval": "\(interval)"
    ]

    return self.request(account, path: "feed/data", queryItems: queryItems).map { resultData -> [DataPoint] in
      return try EmonCMSAPI.dataPoints(fromJsonData: resultData)
    }
  }

  func feedDataDaily(_ account: AccountCredentials, id: String, at startTime: Date, until endTime: Date) -> Observable<[DataPoint]> {
    let queryItems = [
      "id": id,
      "start": "\(UInt64(startTime.timeIntervalSince1970 * 1000))",
      "end": "\(UInt64(endTime.timeIntervalSince1970 * 1000))",
      "mode": "daily"
    ]

    return self.request(account, path: "feed/data", queryItems: queryItems).map { resultData -> [DataPoint] in
      return try EmonCMSAPI.dataPoints(fromJsonData: resultData)
    }
  }

  func feedValue(_ account: AccountCredentials, id: String) -> Observable<Double> {
    let queryItems = [
      "id": id
    ]

    return self.request(account, path: "feed/value", queryItems: queryItems).map { resultData -> Double in
      guard let json = try? JSONSerialization.jsonObject(with: resultData, options: [.allowFragments]),
        let value = Double.from(json) else {
          throw EmonCMSAPIError.invalidResponse
      }

      return value
    }
  }

  func feedValue(_ account: AccountCredentials, ids: [String]) -> Observable<[String:Double]> {
    let queryItems = [
      "ids": ids.joined(separator: ",")
    ]

    return self.request(account, path: "feed/fetch", queryItems: queryItems).map { resultData -> [String:Double] in
      guard let json = try? JSONSerialization.jsonObject(with: resultData),
        let array = json as? [Any] else {
          throw EmonCMSAPIError.invalidResponse
      }

      var results: [String:Double] = [:]
      for (id, valueAny) in zip(ids, array) {
        guard let value = Double.from(valueAny) else {
          throw EmonCMSAPIError.invalidResponse
        }

        results[id] = value
      }
      return results
    }
  }

}
