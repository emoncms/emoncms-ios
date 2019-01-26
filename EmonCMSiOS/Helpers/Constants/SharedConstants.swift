//
//  SharedConstants.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 25/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

struct SharedConstants {

  enum ApplicationContextKeys: String {
    case accountUUID
    case accountURL
    case accountApiKey
  }

  enum UserDefaultsKeys: String {
    case accountURL
    case accountUUID
    case lastSelectedAccountUUID
  }

  static let EmonCMSdotOrgURL = "https://www.emoncms.org/"

}
