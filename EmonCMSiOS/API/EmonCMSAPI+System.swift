//
//  EmonCMSAPI+System.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/04/2022.
//  Copyright © 2022 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

extension EmonCMSAPI {
  func version(_ account: AccountCredentials) -> AnyPublisher<String, APIError> {
    return self.request(account, path: "version").tryMap { resultData -> String in
      String(data: resultData, encoding: .utf8) ?? "0"
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }
}
