//
//  EmonCMSiOSWidgetBundle.swift
//  EmonCMSiOSWidgetExtension
//
//  Created by Matt Galloway on 20/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import SwiftUI
import WidgetKit

@main
struct EmonCMSiOSWidgetBundle: WidgetBundle {
  init() {
    LogController.shared.initialise()
  }

  @WidgetBundleBuilder
  var body: some Widget {
    FeedListWidget()
    SingleFeedWidget()
  }
}
