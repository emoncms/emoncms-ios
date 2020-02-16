//
//  AccountData.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class Account: Object {
  @objc dynamic var uuid: String = UUID().uuidString
  @objc dynamic var name: String = ""
  @objc dynamic var url: String = ""

  override class func primaryKey() -> String? {
    return "uuid"
  }
}
