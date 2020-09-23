//
//  AppBoxViewsTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import SnapshotTesting
import XCTest

class AppBoxViewsTests: XCTestCase {
  override func setUp() {
    super.setUp()
    isRecording = false
  }

  func testArrowViewUp() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .up
    assertSnapshot(matching: view, as: .image)
  }

  func testArrowViewDown() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .down
    assertSnapshot(matching: view, as: .image)
  }

  func testArrowViewLeft() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .left
    assertSnapshot(matching: view, as: .image)
  }

  func testArrowViewRight() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .right
    assertSnapshot(matching: view, as: .image)
  }

  func testArrowViewArrowColor() {
    let view = AppBoxesArrowView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .white
    view.value = 100
    view.unit = "kWh"
    view.direction = .up
    view.arrowColor = .red
    assertSnapshot(matching: view, as: .image)
  }

  func testFeedView() {
    let view = AppBoxesFeedView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    view.backgroundColor = .red
    view.name = "Feed"
    view.unit = "kWh"
    view.value = 100
    assertSnapshot(matching: view, as: .image)
  }
}
