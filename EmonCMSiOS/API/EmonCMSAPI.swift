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

  enum APIError: Error {
    case failedToCreateURL
    case requestFailed
    case atsFailed
    case invalidCredentials
    case invalidResponse
  }

  init(requestProvider: HTTPRequestProvider) {
    self.requestProvider = requestProvider
  }

  private class func buildURL(_ account: AccountCredentials, path: String, queryItems: [String:String] = [:]) throws -> URL {
    let fullUrl = account.url + "/" + path + ".json"
    guard var urlBuilder = URLComponents(string: fullUrl) else {
      throw APIError.failedToCreateURL
    }

    var allQueryItems = queryItems
    allQueryItems["apikey"] = account.apiKey
    urlBuilder.queryItems = allQueryItems.map() { URLQueryItem(name: $0, value: $1) }

    if let url = urlBuilder.url {
      return url
    } else {
      throw APIError.failedToCreateURL
    }
  }

  func request(_ account: AccountCredentials, path: String, queryItems: [String:String] = [:]) -> Observable<Data> {
    let url: URL
    do {
      url = try EmonCMSAPI.buildURL(account, path: path, queryItems: queryItems)
    } catch {
      return Observable.error(error)
    }

    return self.requestProvider.request(url: url)
      .catchError { error -> Observable<Data> in
        AppLog.info("Network request error: \(error)")

        let returnError: APIError
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

  class func extractAPIDetailsFromURLString(_ url: String) -> AccountCredentials? {
    do {
      let regex = try NSRegularExpression(pattern: "^(http[s]?://.*)/app\\?[readkey=]+=([^&]+)#myelectric", options: [])
      let nsStringUrl = url as NSString
      let matches = regex.matches(in: url, options: [], range: NSMakeRange(0, nsStringUrl.length))
      if let match = matches.first, match.numberOfRanges == 3 {
        let host = nsStringUrl.substring(with: match.range(at: 1))
        let apiKey = nsStringUrl.substring(with: match.range(at: 2))
        return AccountCredentials(url: host, apiKey: apiKey)
      }
    } catch {}
    return nil
  }

}
