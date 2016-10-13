//
//  AppDataModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

protocol AppConfigField {

  var id: String { get }
  var name: String { get }
  var optional: Bool { get }

}

struct AppConfigFieldString: AppConfigField {

  let id: String
  let name: String
  let optional: Bool

}

struct AppConfigFieldFeed: AppConfigField {

  let id: String
  let name: String
  let optional: Bool

  let defaultName: String

}
