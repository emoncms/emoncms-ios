//
//  EmonCMSAPI.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

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

  private class func buildURL(_ account: AccountCredentials, path: String, queryItems: [String: String] = [:]) -> URL? {
    let fullUrl = account.url + "/" + path + ".json"
    guard var urlBuilder = URLComponents(string: fullUrl) else {
      return nil
    }

    var allQueryItems = queryItems
    allQueryItems["apikey"] = account.apiKey
    urlBuilder.queryItems = allQueryItems.map { URLQueryItem(name: $0, value: $1) }

    if let url = urlBuilder.url {
      return url
    } else {
      return nil
    }
  }

  private func convertNetworkError(_ error: HTTPRequestProviderError) -> APIError {
    switch error {
    case .httpError(let code):
      if code == 401 {
        return .invalidCredentials
      } else {
        return .requestFailed
      }
    case .atsFailed:
      return .atsFailed
    case .networkError, .unknown:
      return .requestFailed
    }
  }

  func request(_ baseUrl: String, path: String, username: String, password: String) -> AnyPublisher<Data, APIError> {
    let fullUrlString = baseUrl + "/" + path + ".json"
    guard let url = URL(string: fullUrlString) else {
      return Fail(error: APIError.requestFailed).eraseToAnyPublisher()
    }

    return self.requestProvider.request(url: url, formData: ["username": username, "password": password])
      .mapError { [weak self] error in
        guard let self = self else { return .requestFailed }
        AppLog.info("Network request error: \(error)")
        return self.convertNetworkError(error)
      }
      .eraseToAnyPublisher()
  }

  func request(_ account: AccountCredentials, path: String,
               queryItems: [String: String] = [:]) -> AnyPublisher<Data, APIError>
  {
    guard let url = EmonCMSAPI.buildURL(account, path: path, queryItems: queryItems) else {
      return Fail(error: APIError.failedToCreateURL).eraseToAnyPublisher()
    }

    return self.requestProvider.request(url: url)
      .mapError { [weak self] error in
        guard let self = self else { return APIError.requestFailed }
        AppLog.info("Network request error: \(error)")
        return self.convertNetworkError(error)
      }
      .eraseToAnyPublisher()
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
