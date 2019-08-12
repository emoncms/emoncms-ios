//
//  EmonCMSAPI+Feed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 21/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

extension EmonCMSAPI {

  func feedList(_ account: AccountCredentials) -> AnyPublisher<[Feed], APIError> {
    return self.request(account, path: "feed/list").tryMap { resultData -> [Feed] in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
        let json = anyJson as? [Any] else {
          throw APIError.invalidResponse
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
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }

  func feedFields(_ account: AccountCredentials, id: String) -> AnyPublisher<Feed, APIError> {
    let queryItems = [
      "id": id
    ]

    return self.request(account, path: "feed/aget", queryItems: queryItems).tryMap { resultData -> Feed in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
        let json = anyJson as? [String: Any],
        let feed = Feed.from(json: json) else {
          throw APIError.invalidResponse
      }

      return feed
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }

  func feedField(_ account: AccountCredentials, id: String, fieldName: String) -> AnyPublisher<String, APIError> {
    let queryItems = [
      "id": id,
      "field": fieldName
    ]

    return self.request(account, path: "feed/get", queryItems: queryItems).tryMap { resultData -> String in
      guard let json = try? JSONSerialization.jsonObject(with: resultData, options: [.allowFragments]),
        let value = json as? String else {
          throw APIError.invalidResponse
      }

      return value
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }

  private static func dataPoints(fromJsonData data: Data) throws -> [DataPoint<Double>] {
    guard let json = try? JSONSerialization.jsonObject(with: data),
      let dataPointsJson = json as? [Any] else {
        throw APIError.invalidResponse
    }

    var dataPoints: [DataPoint<Double>] = []
    for dataPointJson in dataPointsJson {
      guard let typedDataPoint = dataPointJson as? [Double] else {
        continue
      }
      if let dataPoint = DataPoint<Double>.from(json: typedDataPoint) {
        dataPoints.append(dataPoint)
      }
    }
    return dataPoints
  }

  func feedData(_ account: AccountCredentials, id: String, at startTime: Date, until endTime: Date, interval: Int) -> AnyPublisher<[DataPoint<Double>], APIError> {
    let queryItems = [
      "id": id,
      "start": "\(UInt64(startTime.timeIntervalSince1970 * 1000))",
      "end": "\(UInt64(endTime.timeIntervalSince1970 * 1000))",
      "interval": "\(interval)"
    ]

    return self.request(account, path: "feed/data", queryItems: queryItems).tryMap { resultData -> [DataPoint<Double>] in
      return try EmonCMSAPI.dataPoints(fromJsonData: resultData)
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }

  func feedDataDaily(_ account: AccountCredentials, id: String, at startTime: Date, until endTime: Date) -> AnyPublisher<[DataPoint<Double>], APIError> {
    let queryItems = [
      "id": id,
      "start": "\(UInt64(startTime.timeIntervalSince1970 * 1000))",
      "end": "\(UInt64(endTime.timeIntervalSince1970 * 1000))",
      "mode": "daily"
    ]

    return self.request(account, path: "feed/data", queryItems: queryItems).tryMap { resultData -> [DataPoint<Double>] in
      return try EmonCMSAPI.dataPoints(fromJsonData: resultData)
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }

  func feedValue(_ account: AccountCredentials, id: String) -> AnyPublisher<Double, APIError> {
    let queryItems = [
      "id": id
    ]

    return self.request(account, path: "feed/value", queryItems: queryItems).tryMap { resultData -> Double in
      guard let json = try? JSONSerialization.jsonObject(with: resultData, options: [.allowFragments]),
        let value = Double.from(json) else {
          throw APIError.invalidResponse
      }

      return value
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }

  func feedValue(_ account: AccountCredentials, ids: [String]) -> AnyPublisher<[String:Double], APIError> {
    let queryItems = [
      "ids": ids.joined(separator: ",")
    ]

    return self.request(account, path: "feed/fetch", queryItems: queryItems).tryMap { resultData -> [String:Double] in
      guard let json = try? JSONSerialization.jsonObject(with: resultData),
        let array = json as? [Any] else {
          throw APIError.invalidResponse
      }

      var results: [String:Double] = [:]
      for (id, valueAny) in zip(ids, array) {
        guard let value = Double.from(valueAny) else {
          throw APIError.invalidResponse
        }

        results[id] = value
      }
      return results
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }

}
