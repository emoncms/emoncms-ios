//
//  Feed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class Feed: Object {
  @objc dynamic var id: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var tag: String = ""
  @objc dynamic var time: Date = Date()
  @objc dynamic var value: Double = 0

  override class func primaryKey() -> String? {
    return "id"
  }
}

extension Feed {
  static func from(json: [String: Any]) -> Feed? {
    guard let id = json["id"] as? String else { return nil }
    guard let name = json["name"] as? String else { return nil }
    guard let tag = json["tag"] as? String else { return nil }
    guard let timeAny = json["time"],
      let timeDouble = Double.from(timeAny) else { return nil }
    guard let valueAny = json["value"],
      let value = Double.from(valueAny) else { return nil }

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
