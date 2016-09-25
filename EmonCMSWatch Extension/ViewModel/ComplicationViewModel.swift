//
//  ComplicationViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 25/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

class ComplicationViewModel {

  struct FeedData {
    let name: String
    let value: String
  }

  private let account: Account?

  init(account: Account?) {
    self.account = account
  }

  func currentFeedData() -> FeedData {
    return FeedData(name: "use", value: "123")
  }

  static func placeholderFeedData() -> FeedData {
    return FeedData(name: "use", value: "123")
  }

}
