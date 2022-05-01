//
//  SemanticVersion.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 29/04/2022.
//  Copyright © 2022 Matt Galloway. All rights reserved.
//

import Foundation

struct SemanticVersion {
  let major: Int
  let minor: Int
  let patch: Int

  var string: String {
    return "\(self.major).\(self.minor).\(self.patch)"
  }

  init?(string: String) {
    let components = string
      .split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
      .compactMap { Int($0) }
    guard components.count == 3 else { return nil }
    self.init(major: components[0], minor: components[1], patch: components[2])
  }

  init(major: Int, minor: Int, patch: Int) {
    self.major = major
    self.minor = minor
    self.patch = patch
  }
}

extension SemanticVersion: Equatable {
  static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
  }
}

extension SemanticVersion: Comparable {
  static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    let a = [lhs.major, lhs.minor, lhs.patch]
    let b = [rhs.major, rhs.minor, rhs.patch]
    return a.lexicographicallyPrecedes(b)
  }
}
