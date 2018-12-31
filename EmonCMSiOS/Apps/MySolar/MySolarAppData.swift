//
//  MySolarAppData.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/12/2018.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

final class MySolarAppData {

  var uuid: String = UUID().uuidString
  var name: String = "MySolar"
  var useFeedId: String?
  var useKwhFeedId: String?
  var solarFeedId: String?
  var solarKwhFeedId: String?

}
