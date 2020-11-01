//
//  DataController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/11/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Foundation

final class DataController {
  static var sharedDataDirectory: URL {
    return FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.SharedApplicationGroupIdentifier)!
  }

  private init() {}
}
