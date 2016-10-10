//
//  AppProtocols.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

struct AppConfigField {

  enum FieldType {
    case string
    case feed
  }

  let id: String
  let name: String
  let type: FieldType

}
