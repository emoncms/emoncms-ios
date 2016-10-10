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
    guard let timeAny = json["time"],
      let timeDouble = Double(timeAny) else { return nil }
    guard let valueAny = json["value"],
      let value = Double(valueAny) else { return nil }

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

extension Double {

  init?(_ value: Any) {
    switch value {
    case let double as Double:
      self.init(double)
    case let float as Float:
      self.init(float)
    case let int as Int:
      self.init(int)
    case let string as String:
      self.init(string)
    default:
      return nil
    }
  }

}
