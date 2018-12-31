//
//  MyElectricAppData.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RealmSwift

final class MyElectricAppData {

  var uuid: String = UUID().uuidString
  var name: String = "MyElectric"
  var useFeedId: String?
  var kwhFeedId: String?

}
