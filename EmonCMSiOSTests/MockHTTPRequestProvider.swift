//
//  MockHTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit
import Combine

@testable import EmonCMSiOS

final class MockHTTPRequestProvider: HTTPRequestProvider {

  func request(url: URL) -> AnyPublisher<Data, HTTPRequestProviderError> {
    guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
      else {
        return Empty<Data, HTTPRequestProviderError>().eraseToAnyPublisher()
    }

    let path = urlComponents.path
    let queryItems = urlComponents.queryItems ?? []
    let queryValues = queryItems.reduce([String:String]()) { (dictionary, item) in
      var mutableDictionary = dictionary
      mutableDictionary[item.name] = item.value ?? ""
      return mutableDictionary
    }

    guard
      queryValues["apikey"] == "ilikecats" ||
      (queryValues["username"] == "username" && queryValues["password"] == "ilikecats")
    else {
      return Fail(error: .httpError(code: 401)).eraseToAnyPublisher()
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
    case "/dashboard/list.json":
      responseString = "[{\"id\":1,\"alias\":\"\",\"name\":\"dash1\",\"description\":\"\"},{\"id\":2,\"alias\":\"\",\"name\":\"dash2\",\"description\":\"\"}]"
    case "/user/auth.json":
      responseString = "{\"success\":true,\"apikey_read\":\"abcdef\"}"
    default:
      break
    }

    if let responseString = responseString, let responseData = responseString.data(using: .utf8) {
      return Just<Data>(responseData).setFailureType(to: HTTPRequestProviderError.self).eraseToAnyPublisher()
    }

    return Empty<Data, HTTPRequestProviderError>().eraseToAnyPublisher()
  }

  func request(url: URL, formData: [String:String]) -> AnyPublisher<Data, HTTPRequestProviderError> {
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return Fail(error: .unknown).eraseToAnyPublisher() }

    var queryItems = components.queryItems ?? [URLQueryItem]()
    queryItems.append(contentsOf: formData.map { URLQueryItem(name: $0, value: $1) } )
    components.queryItems = queryItems

    return self.request(url: components.url!)
  }

}
