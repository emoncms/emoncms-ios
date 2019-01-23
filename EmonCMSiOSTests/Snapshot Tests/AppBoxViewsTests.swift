//
//  AppBoxViewsTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import FBSnapshotTestCase
import Nimble
@testable import EmonCMSiOS

class AppBoxViewsTests: FBSnapshotTestCase {

  override func setUp() {
    super.setUp()
    self.recordMode = false
  }

  func testArrowViewUp() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .up
    FBSnapshotVerifyView(view)
  }

  func testArrowViewDown() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .down
    FBSnapshotVerifyView(view)
  }

  func testArrowViewLeft() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .left
    FBSnapshotVerifyView(view)
  }

  func testArrowViewRight() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .right
    FBSnapshotVerifyView(view)
  }

  func testArrowViewArrowColor() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .up
    view.arrowColor = .red
    FBSnapshotVerifyView(view)
  }

  func testFeedView() {
    let view = AppBoxesFeedView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .red
    view.feedName = "Feed"
    view.feedUnit = "kWh"
    view.feedValue = 100
    FBSnapshotVerifyView(view)
  }

}
