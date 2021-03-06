//
//  HTTPRequestProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

enum HTTPRequestProviderError: Error, Equatable {
  case unknown
  case networkError
  case atsFailed
  case httpError(code: Int)
}

protocol HTTPRequestProvider {
  func request(url: URL) -> AnyPublisher<Data, HTTPRequestProviderError>
  func request(url: URL, formData: [String: String]) -> AnyPublisher<Data, HTTPRequestProviderError>
}
