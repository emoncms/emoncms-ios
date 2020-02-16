//
//  EntwineAdditions.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 17/08/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Entwine
import EntwineTest

extension Signal {
  var value: Input? {
    guard case .input(let v) = self else { return nil }
    return v
  }
}
