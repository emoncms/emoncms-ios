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

  init() {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    self.session = session
  }

  func request(url: URL) -> Observable<Data> {
    return self.session.rx.data(request: URLRequest(url: url))
      .catchError { error -> Observable<Data> in
        let returnError: HTTPRequestProviderError
        if let error = error as? RxCocoaURLError {
          switch error {
          case .httpRequestFailed(let response, _):
            returnError = .httpError(code: response.statusCode)
          case .nonHTTPResponse(_):
            returnError = .networkError
          case .unknown, .deserializationError(_):
            returnError = .unknown
          }
        } else {
          let nsError = error as NSError
          if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
            returnError = .atsFailed
          } else {
            returnError = .unknown
          }
        }

        return Observable.error(returnError)
      }
  }

}
