//
//  EmonCMSAPI.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

final class EmonCMSAPI {

  private let requestProvider: HTTPRequestProvider

  enum EmonCMSAPIError: Error {
    case failedToCreateURL
    case requestFailed
    case atsFailed
    case invalidCredentials
    case invalidResponse
  }

  init(requestProvider: HTTPRequestProvider) {
    self.requestProvider = requestProvider
  }

  private class func buildURL(_ account: Account, path: String, queryItems: [String:String] = [:]) throws -> URL {
    let fullUrl = account.url + "/" + path + ".json"
    guard var urlBuilder = URLComponents(string: fullUrl) else {
      throw EmonCMSAPIError.failedToCreateURL
    }

    var allQueryItems = queryItems
    allQueryItems["apikey"] = account.apikey
    urlBuilder.queryItems = allQueryItems.map() { URLQueryItem(name: $0, value: $1) }

    if let url = urlBuilder.url {
      return url
    } else {
      throw EmonCMSAPIError.failedToCreateURL
    }
  }

  private func request(_ account: Account, path: String, queryItems: [String:String] = [:]) -> Observable<Data> {
    let url: URL
    do {
      url = try EmonCMSAPI.buildURL(account, path: path, queryItems: queryItems)
    } catch {
      return Observable.error(error)
    }

    return self.requestProvider.request(url: url)
      .catchError { error -> Observable<Data> in
        AppLog.info("Network request error: \(error)")

        let returnError: EmonCMSAPIError
        if let error = error as? HTTPRequestProviderError {
          switch error {
          case .httpError(let code):
            if code == 401 {
              returnError = .invalidCredentials
            } else {
              returnError = .requestFailed
            }
          case .atsFailed:
            returnError = .atsFailed
          case .networkError, .unknown:
            returnError = .requestFailed
          }
        } else {
          returnError = .requestFailed
        }

        return Observable.error(returnError)
      }
  }

  func feedList(_ account: Account) -> Observable<[Feed]> {
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

  func feedFields(_ account: Account, id: String) -> Observable<Feed> {
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

  func feedField(_ account: Account, id: String, fieldName: String) -> Observable<String> {
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

  func feedData(_ account: Account, id: String, at startTime: Date, until endTime: Date, interval: Int) -> Observable<[DataPoint]> {
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

  func feedDataDaily(_ account: Account, id: String, at startTime: Date, until endTime: Date) -> Observable<[DataPoint]> {
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

  func feedValue(_ account: Account, id: String) -> Observable<Double> {
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

  func feedValue(_ account: Account, ids: [String]) -> Observable<[String:Double]> {
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

  func inputList(_ account: Account) -> Observable<[Input]> {
    return self.request(account, path: "input/list").map { resultData -> [Input] in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
        let json = anyJson as? [Any] else {
          throw EmonCMSAPIError.invalidResponse
      }

      var inputs: [Input] = []
      for i in json {
        if let inputJson = i as? [String:Any],
          let input = Input.from(json: inputJson) {
          inputs.append(input)
        }
      }

      return inputs
    }
  }

  class func extractAPIDetailsFromURLString(_ url: String) -> (host: String, apikey: String)? {
    do {
      let regex = try NSRegularExpression(pattern: "^(http[s]?://.*)/app\\?[readkey=]+=([^&]+)#myelectric", options: [])
      let nsStringUrl = url as NSString
      let matches = regex.matches(in: url, options: [], range: NSMakeRange(0, nsStringUrl.length))
      if let match = matches.first, match.numberOfRanges == 3 {
        let host = nsStringUrl.substring(with: match.range(at: 1))
        let apikey = nsStringUrl.substring(with: match.range(at: 2))
        return (host: host, apikey: apikey)
      }
    } catch {}
    return nil
  }

}
