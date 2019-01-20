//
//  EmonCMSiOSUITests.swift
//  EmonCMSiOSUITests
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
@testable import EmonCMSiOS

class EmonCMSiOSUITests: QuickSpec {

  override func setUp() {
    super.setUp()
    self.continueAfterFailure = false
  }

  override func spec() {
    var app: XCUIApplication!

    beforeEach {
      app = XCUIApplication()
      app.launchArguments.append("--uitesting")
      app.launch()
    }

    describe("accounts") {
      it("should show empty accounts screen") {
        expect(app.tables[AccessibilityIdentifiers.Lists.Account].exists).to(equal(true))
        expect(app.tables.cells.count).to(equal(0))
        let addAppLabel = app.staticTexts["Tap + to add a new account"]
        expect(addAppLabel.exists).to(equal(true))
      }

      it("should add account successfully for valid details") {
        app.navigationBars["Accounts"].buttons["Add"].tap()

        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.textFields["Emoncms instance name"]/*[[".cells.textFields[\"Emoncms instance name\"]",".textFields[\"Emoncms instance name\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.typeText("Test Instance")
        tablesQuery/*@START_MENU_TOKEN@*/.textFields["Emoncms instance URL"]/*[[".cells.textFields[\"Emoncms instance URL\"]",".textFields[\"Emoncms instance URL\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.typeText("https://localhost")
        tablesQuery/*@START_MENU_TOKEN@*/.textFields["Emoncms API read Key"]/*[[".cells.textFields[\"Emoncms API read Key\"]",".textFields[\"Emoncms API read Key\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.typeText("ilikecats")

        app.navigationBars["Account Details"].buttons["Save"].tap()

        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: 1)).to(equal(true))
      }

      it("should error for invalid credentials") {
        app.navigationBars["Accounts"].buttons["Add"].tap()

        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.textFields["Emoncms instance name"]/*[[".cells.textFields[\"Emoncms instance name\"]",".textFields[\"Emoncms instance name\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.typeText("Test Instance")
        tablesQuery/*@START_MENU_TOKEN@*/.textFields["Emoncms instance URL"]/*[[".cells.textFields[\"Emoncms instance URL\"]",".textFields[\"Emoncms instance URL\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.typeText("https://localhost")
        tablesQuery/*@START_MENU_TOKEN@*/.textFields["Emoncms API read Key"]/*[[".cells.textFields[\"Emoncms API read Key\"]",".textFields[\"Emoncms API read Key\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.typeText("notthekey")

        app.navigationBars["Account Details"].buttons["Save"].tap()

        expect(app.alerts["Error"].exists).to(equal(true))
      }
    }
  }

}
