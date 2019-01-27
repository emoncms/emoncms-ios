//
//  TodayWidgetFeed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class TodayWidgetFeed: Object {

  @objc dynamic var uuid: String = UUID().uuidString
  @objc dynamic var order: Int = 0
  @objc dynamic var accountId: String = ""
  @objc dynamic var feedId: String = ""

  override class func primaryKey() -> String? {
    return "uuid"
  }

}
