//
//  Feed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

class Feed: Object {

  dynamic var id: String = ""
  dynamic var name: String = ""
  dynamic var tag: String = ""
  dynamic var time: Date = Date()
  dynamic var value: Double = 0

  override class func primaryKey() -> String? {
    return "id"
  }

}

extension Feed {

  static func from(json: [String:Any]) -> Feed? {
    guard let id = json["id"] as? String else { return nil }
    guard let name = json["name"] as? String else { return nil }
    guard let tag = json["tag"] as? String else { return nil }
    guard let timeString = json["time"] as? String,
      let timeDouble = Double(timeString) else { return nil }
    guard let valueString = json["value"] as? String,
      let value = Double(valueString) else { return nil }

    let time = Date(timeIntervalSince1970: timeDouble)

    let feed = Feed()
    feed.id = id
    feed.name = name
    feed.tag = tag
    feed.time = time
    feed.value = value

    return feed
  }

}
