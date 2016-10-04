//
//  NSURLSessionHTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 04/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

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
    return Observable.create { observer in
      let task = self.session.dataTask(with: url) { (data, response, error) in
        if let data = data {
          observer.onNext(data)
          observer.onCompleted()
        } else {
          observer.onError(NSURLSessionHTTPRequestProviderError.RequestFailed)
        }
      }
      task.resume()
      return Disposables.create {
        task.cancel()
      }
    }
  }

}
