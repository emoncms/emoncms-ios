//
//  HTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

enum HTTPRequestProviderError: Error {
  case unknown
  case networkError
  case atsFailed
  case httpError(code: Int)
}

protocol HTTPRequestProvider {

  func request(url: URL) -> Observable<Data>
  func request(url: URL, formData: [String:String]) -> Observable<Data>

}
