//
//  FormatHelpers.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

extension Double {

  func prettyFormat(decimals: Int? = nil) -> String {
    let actualDecimals: Int
    if let decimals = decimals {
      actualDecimals = decimals
    } else {
      if self < 10 {
        actualDecimals = 2
      } else if self < 100 {
        actualDecimals = 1
      } else {
        actualDecimals = 0
      }
    }

    return String(format: "%.\(actualDecimals)f", self)
  }

}
