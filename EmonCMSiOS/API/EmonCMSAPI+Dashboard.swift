//
//  EmonCMSAPI+Dashboard.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

extension EmonCMSAPI {

  func dashboardList(_ account: AccountCredentials) -> Observable<[Dashboard]> {
    return self.request(account, path: "dashboard/list").map { resultData -> [Dashboard] in
      guard let anyJson = try? JSONSerialization.jsonObject(with: resultData, options: []),
        let json = anyJson as? [Any] else {
          throw APIError.invalidResponse
      }

      var dashboards: [Dashboard] = []
      for i in json {
        if let dashboardJson = i as? [String:Any],
          let dashboard = Dashboard.from(json: dashboardJson) {
          dashboards.append(dashboard)
        }
      }

      return dashboards
    }
  }

}
