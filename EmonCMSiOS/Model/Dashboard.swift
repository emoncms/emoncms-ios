//
//  Dashboard.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class Dashboard: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var desc: String = ""
  @objc dynamic var alias: String = ""

  override class func primaryKey() -> String? {
    return "id"
  }

}

extension Dashboard {

  static func from(json: [String:Any]) -> Dashboard? {
    guard let id = json["id"] as? Int else { return nil }
    guard let name = json["name"] as? String else { return nil }
    guard let desc = json["description"] as? String else { return nil }
    guard let alias = json["alias"] as? String else { return nil }

    let dashboard = Dashboard()
    dashboard.id = String(id)
    dashboard.name = name
    dashboard.desc = desc
    dashboard.alias = alias

    return dashboard
  }

}
