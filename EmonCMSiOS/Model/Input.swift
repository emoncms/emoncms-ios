//
//  Input.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class Input: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var nodeid: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var desc: String = ""
  @objc dynamic var time: Date = Date()
  @objc dynamic var value: Double = 0

  override class func primaryKey() -> String? {
    return "id"
  }

}

extension Input {

  static func from(json: [String:Any]) -> Input? {
    guard let id = json["id"] as? String else { return nil }
    guard let nodeid = json["nodeid"] as? String else { return nil }
    guard let name = json["name"] as? String else { return nil }
    guard let desc = json["description"] as? String else { return nil }
    guard let timeAny = json["time"],
      let timeDouble = Double(timeAny) else { return nil }
    guard let valueAny = json["value"],
      let value = Double(valueAny) else { return nil }

    let time = Date(timeIntervalSince1970: timeDouble)

    let input = Input()
    input.id = id
    input.nodeid = nodeid
    input.name = name
    input.desc = desc
    input.time = time
    input.value = value

    return input
  }

}
