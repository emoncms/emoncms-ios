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
    static let Yellow = UIColor(hexString: "dccc1f")
    static let Orange = UIColor(hexString: "fb7b50")
  }

  struct Apps {
    static let Solar = UIColor(hexString: "dccc1f")
    static let Grid = UIColor(hexString: "d52e2e")
    static let House = UIColor(hexString: "82cbfc")
    static let Use = UIColor(hexString: "0598fa")
    static let Divert = UIColor(hexString: "fb7b50")
  }

  struct ActivityIndicator {
    static let Green = UIColor(red: 0.196, green: 0.784, blue: 0.196, alpha: 1.0)
    static let Yellow = UIColor(red: 0.94, green: 0.71, blue: 0.078, alpha: 1.0)
    static let Orange = UIColor(red: 1.0, green: 0.49, blue: 0.078, alpha: 1.0)
    static let Red = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
  }

  static let ErrorRed = UIColor(hexString: "e24522")

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
