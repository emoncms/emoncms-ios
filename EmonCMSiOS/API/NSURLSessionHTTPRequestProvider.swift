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

  enum NSURLSessionHTTPRequestProviderError: Error {
    case RequestFailed
  }

  private let session: URLSession

  init() {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    self.session = session
  }

  func request(url: URL) -> Observable<Data> {
    return self.session.rx.data(URLRequest(url: url))
  }

}
