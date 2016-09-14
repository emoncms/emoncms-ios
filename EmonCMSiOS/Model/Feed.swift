//
//  Feed.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Unbox

struct Feed {

  let id: String
  let name: String
  let tag: String
  let time: Date
  let value: Double

}

extension Feed: Unboxable {

  init(unboxer: Unboxer) {
    self.id = unboxer.unbox(key: "id")
    self.name = unboxer.unbox(key: "name")
    self.tag = unboxer.unbox(key: "tag")

    let time: String = unboxer.unbox(key: "time")
    self.time = Date(timeIntervalSince1970: Double(time) ?? 0)

    let value: String = unboxer.unbox(key: "value")
    self.value = Double(value) ?? 0
  }
  
}
