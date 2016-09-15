//
//  AlamofireHTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import Alamofire

class AlamofireHTTPRequestProvider: HTTPRequestProvider {

  enum AlamofireHTTPRequestProviderError: Error {
    case RequestFailed
  }

  func request(url: URL) -> Observable<Data> {
    return Observable.create { observer in
      Alamofire.request(url).responseData { response in
        if let data = response.result.value {
          observer.onNext(data)
          observer.onCompleted()
        } else {
          observer.onError(AlamofireHTTPRequestProviderError.RequestFailed)
        }
      }
      return Disposables.create()
    }
  }

}
