//
//  EmonCMSAPI+Input.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 21/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

extension EmonCMSAPI {

  func inputList(_ account: AccountCredentials) -> Observable<[Input]> {
    return self.request(account, path: "input/list").map { resultData -> [Input] in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
        let json = anyJson as? [Any] else {
          throw EmonCMSAPIError.invalidResponse
      }

      var inputs: [Input] = []
      for i in json {
        if let inputJson = i as? [String:Any],
          let input = Input.from(json: inputJson) {
          inputs.append(input)
        }
      }

      return inputs
    }
  }

}
