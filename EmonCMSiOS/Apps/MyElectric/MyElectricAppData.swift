//
//  MyElectricAppData.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class MyElectricAppData: Object {

  @objc dynamic var uuid: String = UUID().uuidString
  @objc dynamic var name: String = "MyElectric"
  @objc dynamic var useFeedId: String?
  @objc dynamic var kwhFeedId: String?

  override class func primaryKey() -> String? {
    return "uuid"
  }

}
