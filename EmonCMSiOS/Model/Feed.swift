//
//  Feed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

struct Feed {

  let id: String
  let name: String
  let tag: String
  let time: Date
  let value: Double

}

extension Feed {

  init?(json: [String:Any]) {
    guard let id = json["id"] as? String else { return nil }
    guard let name = json["name"] as? String else { return nil }
    guard let tag = json["tag"] as? String else { return nil }
    guard let timeString = json["time"] as? String,
      let timeDouble = Double(timeString) else { return nil }
    guard let valueString = json["value"] as? String,
      let value = Double(valueString) else { return nil }

    let time = Date(timeIntervalSince1970: timeDouble)

    self.init(id: id, name: name, tag: tag, time: time, value: value)
  }
  
}
