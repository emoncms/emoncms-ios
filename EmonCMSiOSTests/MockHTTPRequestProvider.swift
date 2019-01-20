//
//  MockHTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
@testable import EmonCMSiOS

final class MockHTTPRequestProvider: HTTPRequestProvider {

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

    var responseString: String?
    switch path {
    case "/feed/list.json":
      responseString = "[{\"id\":\"1\",\"userid\":\"1\",\"name\":\"use\",\"datatype\":\"1\",\"tag\":\"Node 5\",\"public\":\"0\",\"size\":\"154624\",\"engine\":\"5\",\"processList\":\"\",\"time\":\"1473934060\",\"value\":\"1186\"},{\"id\":\"2\",\"userid\":\"1\",\"name\":\"use_kwh\",\"datatype\":\"1\",\"tag\":\"Node 5\",\"public\":\"0\",\"size\":\"154624\",\"engine\":\"5\",\"processList\":\"\",\"time\":\"1473934060\",\"value\":\"189.12940747385\"}]"
    case "/feed/aget.json":
      responseString = "{\"id\":\"1\",\"userid\":\"1\",\"name\":\"use\",\"datatype\":\"1\",\"tag\":\"Node 5\",\"public\":\"0\",\"size\":\"154624\",\"engine\":\"5\",\"processList\":\"\",\"time\":\"1473946653\",\"value\":\"278\"}"
    case "/feed/get.json":
      responseString = "\"use\""
    case "/feed/data.json":
      if queryValues["mode"] == "daily" {
        responseString = "[[0,0],[86400000,10],[172800000,20]]"
      } else {
        responseString = "[[1473793120000,257],[1473793130000,262],[1473793140000,306],[1473793150000,322],[1473793160000,321],[1473793170000,325],[1473793180000,322],[1473793190000,325],[1473793200000,320],[1473793210000,299]]"
      }
    case "/feed/value.json":
      responseString = "\"100\""
    case "/feed/fetch.json":
      responseString = "[\"100\",\"200\",\"300\"]"
    case "/input/list.json":
      responseString = "[{\"id\":\"1\",\"nodeid\":\"1\",\"name\":\"use\",\"description\":\"\",\"processList\":\"\",\"time\":\"1473934060\",\"value\":\"1186\"},{\"id\":\"2\",\"nodeid\":\"1\",\"name\":\"use_kwh\",\"description\":\"\",\"processList\":\"\",\"time\":\"1473934060\",\"value\":\"189.12940747385\"}]"
    default:
      break
    }

    if let responseString = responseString, let responseData = responseString.data(using: .utf8) {
      return Observable.just(responseData)
    }

    return Observable.empty()
  }

}
