//
//  FeedRowController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import WatchKit

class FeedRowController: NSObject {

  @IBOutlet var nameLabel: WKInterfaceLabel!
  @IBOutlet var valueLabel: WKInterfaceLabel!

  var feed: FeedViewModel? {
    didSet {
      if let feed = feed {
        self.nameLabel.setText(feed.name)
        self.valueLabel.setText(feed.value)
      }
    }
  }

}
