//
//  EmonCMSAPI.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Alamofire
import Unbox

enum EmonCMSAPIResult<T> {
  case Result(T)
  case Error
}

class EmonCMSAPI {

  let account: Account

  private enum EmonCMSAPIError: Error {
    case FailedToCreateURL
  }

  init(account: Account) {
    self.account = account
  }

  private func buildURL(path: String, queryItems: [String:String] = [:]) throws -> URL {
    guard var urlBuilder = URLComponents(string: self.account.url) else {
      throw EmonCMSAPIError.FailedToCreateURL
    }

    urlBuilder.path = "/feed/" + path + ".json"

    var allQueryItems = queryItems
    allQueryItems["apikey"] = self.account.apikey
    urlBuilder.queryItems = allQueryItems.map() { URLQueryItem(name: $0, value: $1) }

    if let url = urlBuilder.url {
      return url
    } else {
      throw EmonCMSAPIError.FailedToCreateURL
    }
  }

  func request(path: String, queryItems: [String:String] = [:], callback: @escaping (Data?) -> Void) {
    let url: URL
    do {
      url = try self.buildURL(path: path, queryItems: queryItems)
    } catch {
      // TODO: Handle errors!
      return
    }
    Alamofire.request(url).responseData { response in
      callback(response.result.value)
      // TODO: Handle errors!
    }
  }

  func feedList(callback: @escaping (EmonCMSAPIResult<[Feed]>) -> Void) {
    self.request(path: "list") { resultData in
      if let resultData = resultData,
        let feeds: [Feed] = try? Unbox(data: resultData) {
        callback(.Result(feeds))
      } else {
        callback(.Error)
      }
    }
  }

  func feedData(id: String, at startTime: Date, until endTime: Date, interval: Int, callback: @escaping (EmonCMSAPIResult<[FeedDataPoint]>) -> Void) {
    let queryItems = [
      "id": id,
      "start": "\(Int(startTime.timeIntervalSince1970 * 1000))",
      "end": "\(Int(endTime.timeIntervalSince1970 * 1000))",
      "interval": "\(interval)"
    ]
    self.request(path: "data", queryItems: queryItems) { resultData in
      guard let resultData = resultData,
          let json = try? JSONSerialization.jsonObject(with: resultData),
        let dataPoints = json as? [Any] else {
          callback(.Error)
          return
      }

      var feedDataPoints: [FeedDataPoint] = []
      for dataPoint in dataPoints {
        guard let typedDataPoint = dataPoint as? [Double] else {
          continue
        }
        if let feedDataPoint = FeedDataPoint.from(dataArray: typedDataPoint) {
          feedDataPoints.append(feedDataPoint)
        }
      }
      callback(.Result(feedDataPoints))
    }
  }

}
