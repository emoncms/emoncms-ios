//
//  Double+Emoncms.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 17/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

extension Double {

  static func from(_ value: Any) -> Double? {
    switch value {
    case let double as Double:
      return double
    case let float as Float:
      return Double(float)
    case let int as Int:
      return Double(int)
    case let string as String:
      return Double(string)
    default:
      return nil
    }
  }

}
