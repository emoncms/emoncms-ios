//
//  NSURLSessionHTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 04/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

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

  private func convertError(_ error: Error) -> HTTPRequestProviderError {
    if let error = error as? RxCocoaURLError {
      switch error {
      case .httpRequestFailed(let response, _):
        return .httpError(code: response.statusCode)
      case .nonHTTPResponse(_):
        return .networkError
      case .unknown, .deserializationError(_):
        return .unknown
      }
    } else {
      let nsError = error as NSError
      if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
        return .atsFailed
      } else {
        return .unknown
      }
    }
  }

  func request(url: URL) -> Observable<Data> {
    let request = URLRequest(url: url)
    return self.data(forRequest: request)
  }

  func request(url: URL, formData: [String:String]) -> Observable<Data> {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let postString = formData.map { "\($0)=\($1)" }.joined(separator: "&")
    request.httpBody = postString.data(using: .utf8)

    return self.data(forRequest: request)
  }

  private func data(forRequest request: URLRequest) -> Observable<Data> {
    return self.session.rx.data(request: request)
      .catchError { [weak self] error in
        guard let self = self else { return Observable.error(HTTPRequestProviderError.unknown) }
        return Observable.error(self.convertError(error))
      }
  }

}
