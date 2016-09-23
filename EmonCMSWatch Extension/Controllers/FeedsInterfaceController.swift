//
//  InterfaceController.swift
//  EmonCMSWatch Extension
//
//  Created by Matt Galloway on 23/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import WatchKit
import Foundation


class FeedsInterfaceController: WKInterfaceController {

  @IBOutlet var feedsTable: WKInterfaceTable!

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)

    self.feedsTable.setNumberOfRows(5, withRowType: "FeedRow")

    for index in 0..<self.feedsTable.numberOfRows {
      if let controller = feedsTable.rowController(at: index) as? FeedRowController {
        controller.feed = FeedViewModel()
      }
    }
  }

}
