//
//  EmonCMSColors.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import UIKit

struct EmonCMSColors {

  struct Chart {
    static let Blue = UIColor(hexString: "3399ff")
    static let DarkBlue = UIColor(hexString: "0779c1")
  }

}

extension UIColor {

  fileprivate convenience init(hexString: String) {
    let r, g, b: CGFloat

    let scanner = Scanner(string: hexString)
    var hexNumber: UInt64 = 0

    if scanner.scanHexInt64(&hexNumber) {
      r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
      g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
      b = CGFloat((hexNumber & 0x000000ff) >> 0) / 255

      self.init(red: r, green: g, blue: b, alpha: 1)
    } else {
      self.init(white: 0, alpha: 1)
    }
  }

}
