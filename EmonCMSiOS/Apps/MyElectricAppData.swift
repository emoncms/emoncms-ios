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

  dynamic var uuid: String = UUID().uuidString
  dynamic var name: String = "MyElectric"
  dynamic var useFeedId: String?
  dynamic var kwhFeedId: String?

  override class func primaryKey() -> String? {
    return "uuid"
  }

}
