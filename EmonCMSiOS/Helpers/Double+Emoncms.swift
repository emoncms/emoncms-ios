//
//  Double+Emoncms.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 17/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

extension Double {

  init?(_ value: Any) {
    switch value {
    case let double as Double:
      self.init(double)
    case let float as Float:
      self.init(float)
    case let int as Int:
      self.init(int)
    case let string as String:
      self.init(string)
    default:
      return nil
    }
  }

}
