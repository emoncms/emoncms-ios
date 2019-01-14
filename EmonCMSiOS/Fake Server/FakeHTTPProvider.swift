//
//  FakeHTTPProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift

final class FakeHTTPProvider: HTTPRequestProvider {

  private static let fakeDataDirectory = "fake_server_data"

  private static let feedValues = [
    "1" : "200",
    "2" : "1000",
    "3" : "100",
    "4" : "1000",
    "5" : "100",
    "6" : "1000",
    ]

  private func feedValue(forId feedId: String) -> String? {
    return FakeHTTPProvider.feedValues[feedId]
  }

  func request(url: URL) -> Observable<Data> {
    guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
      else {
        return Observable.empty()
    }

    let path = urlComponents.path
    let queryItems = urlComponents.queryItems ?? []
    let queryValues = queryItems.reduce([String:String]()) { (dictionary, item) in
      var mutableDictionary = dictionary
      mutableDictionary[item.name] = item.value ?? ""
      return mutableDictionary
    }

    guard queryValues["apikey"] == "ilikecats" else {
      return Observable.error(HTTPRequestProviderError.httpError(code: 401))
    }

    var responseJsonFilename: String?
    var responseString: String?

    switch path {
    case "/feed/list.json":
      responseJsonFilename = "list_response"
    case "/feed/aget.json":
      responseString = "{\"id\":\"1\",\"userid\":\"1\",\"name\":\"use\",\"datatype\":\"1\",\"tag\":\"Node 5\",\"public\":\"0\",\"size\":\"154624\",\"engine\":\"5\",\"processList\":\"\",\"time\":\"1473946653\",\"value\":\"278\"}"
    case "/feed/get.json":
      responseString = "\"use\""
    case "/feed/data.json":
      if queryValues["mode"] == "daily" {
        responseString = "[[0,0],[86400000,10],[172800000,20]]"
      } else {
        switch queryValues["id"] {
        case "1":
          responseJsonFilename = "data_use_response"
        case "5":
          responseJsonFilename = "data_solar_response"
        default:
          responseJsonFilename = "data_s_response"
        }
      }
    case "/feed/value.json":
      if
        let feedId = queryValues["id"],
        let feedValue = self.feedValue(forId: feedId)
      {
        responseString = "\"\(feedValue)\""
      }
    case "/feed/fetch.json":
      var feedValues = [String]()
      if let feedIds = queryValues["ids"]?.split(separator: ",") {
        for feedId in feedIds {
          if let feedValue = self.feedValue(forId: String(feedId)) {
            feedValues.append("\"\(feedValue)\"")
          }
        }
      }
      responseString = "[\(feedValues.joined(separator: ","))]"
    default:
      break
    }

    let responseData: Data?
    if
      let responseString = responseString
    {
      responseData = responseString.data(using: .utf8)
    }
    else if
      let responseJsonFilename = responseJsonFilename,
      let responseFileURL = Bundle.main.url(forResource: responseJsonFilename, withExtension: "json", subdirectory: FakeHTTPProvider.fakeDataDirectory)
    {
      responseData = try? Data(contentsOf: responseFileURL)
    }
    else {
      responseData = nil
    }

    if let responseData = responseData {
      return Observable.just(responseData)
    }

    return Observable.error(HTTPRequestProviderError.unknown)
  }

}
