//
//  EmonCMSAPI+User.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 25/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

extension EmonCMSAPI {
  func userAuth(url: String, username: String, password: String) -> AnyPublisher<String, APIError> {
    return self.request(url, path: "user/auth", username: username, password: password).tryMap { resultData -> String in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
            let json = anyJson as? [String: Any]
      else {
        throw APIError.invalidResponse
      }

      guard
        let success = json["success"] as? Bool,
        success == true,
        let apiKey = json["apikey_read"] as? String
      else {
        throw APIError.invalidCredentials
      }

      return apiKey
    }
    .mapError { error -> APIError in
      if let error = error as? APIError { return error }
      return APIError.requestFailed
    }
    .eraseToAnyPublisher()
  }
}
