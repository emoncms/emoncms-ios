//
//  EmonCMSAPI.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import Alamofire
import Unbox

class EmonCMSAPI {

  let account: Account

  private enum EmonCMSAPIError: Error {
    case FailedToCreateURL
    case RequestFailed
    case InvalidResponse
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

  func request(path: String, queryItems: [String:String] = [:]) -> Observable<Data> {
    let url: URL
    do {
      url = try self.buildURL(path: path, queryItems: queryItems)
    } catch {
      return Observable.error(error)
    }

    return Observable.create { observer in
      Alamofire.request(url).responseData { response in
        if let data = response.result.value {
          observer.onNext(data)
          observer.onCompleted()
        } else {
          observer.onError(EmonCMSAPIError.RequestFailed)
        }
      }
      return Disposables.create()
    }
  }

  func feedList() -> Observable<[Feed]> {
    return self.request(path: "list").map { resultData -> [Feed] in
      do {
        let feeds: [Feed] = try Unbox(data: resultData)
        return feeds
      } catch {
        throw EmonCMSAPIError.InvalidResponse
      }
    }
  }

  func feedData(id: String, at startTime: Date, until endTime: Date, interval: Int) -> Observable<[FeedDataPoint]> {
    let queryItems = [
      "id": id,
      "start": "\(Int(startTime.timeIntervalSince1970 * 1000))",
      "end": "\(Int(endTime.timeIntervalSince1970 * 1000))",
      "interval": "\(interval)"
    ]

    return self.request(path: "data", queryItems: queryItems).map { resultData -> [FeedDataPoint] in
      guard let json = try? JSONSerialization.jsonObject(with: resultData),
        let dataPoints = json as? [Any] else {
          throw EmonCMSAPIError.InvalidResponse
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
      return feedDataPoints
    }
  }

}
