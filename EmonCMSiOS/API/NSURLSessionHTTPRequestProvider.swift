//
//  NSURLSessionHTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 04/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

final class NSURLSessionHTTPRequestProvider: HTTPRequestProvider {

  private let session: URLSession

  init(session: URLSession) {
    self.session = session
  }

  convenience init() {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    self.init(session: session)
  }

  func request(url: URL) -> AnyPublisher<Data, HTTPRequestProviderError> {
    let request = URLRequest(url: url)
    return self.data(forRequest: request)
  }

  func request(url: URL, formData: [String:String]) -> AnyPublisher<Data, HTTPRequestProviderError> {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let postString = formData.map { "\($0)=\($1)" }.joined(separator: "&")
    request.httpBody = postString.data(using: .utf8)

    return self.data(forRequest: request)
  }

  private func data(forRequest request: URLRequest) -> AnyPublisher<Data, HTTPRequestProviderError> {
    return self.session.dataTaskPublisher(for: request)
      .tryMap { data, response -> Data in
        guard let httpResponse = response as? HTTPURLResponse else {
          throw HTTPRequestProviderError.networkError
        }
        guard 200..<300 ~= httpResponse.statusCode else {
          throw HTTPRequestProviderError.httpError(code: httpResponse.statusCode)
        }
        return data
      }
      .mapError{ error -> HTTPRequestProviderError in
        if let e = error as? HTTPRequestProviderError {
          return e
        }

        if let e = error as? URLError {
          switch e.code {
          case URLError.appTransportSecurityRequiresSecureConnection:
            return .atsFailed
          default:
            return .unknown
          }
        }

        return .unknown
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }

}
