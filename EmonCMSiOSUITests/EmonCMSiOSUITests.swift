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

    func loginFromAccountList(name: String, url: String, apiKey: String) {
      app.navigationBars["Accounts"].buttons["Add"].tap()

      let tablesQuery = app.tables
      tablesQuery.textFields["Emoncms instance name"].tap()
      app.typeText(name)
      tablesQuery.textFields["Emoncms instance URL"].tap()
      app.typeText(url)
      tablesQuery.textFields["Emoncms API read Key"].tap()
      app.typeText(apiKey)

      app.navigationBars["Account Details"].buttons["Save"].tap()
    }

    func loginFromAccountListWithValidCredentials() {
      loginFromAccountList(name: "Test Instance", url: "https://localhost", apiKey: "ilikecats")
    }

    describe("accounts") {
      it("should show empty accounts screen") {
        expect(app.tables[AccessibilityIdentifiers.Lists.Account].exists).to(equal(true))
        expect(app.tables[AccessibilityIdentifiers.Lists.Account].cells.count).to(equal(0))
        let addAccountLabel = app.staticTexts["Tap + to add a new account"]
        expect(addAccountLabel.exists).to(equal(true))
      }

      it("should add account successfully for valid details") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: 1)).to(equal(true))
      }

      it("should error for invalid credentials") {
        loginFromAccountList(name: "Test Instance", url: "https://localhost", apiKey: "notthekey")
        expect(app.alerts["Error"].exists).to(equal(true))
      }
    }

    describe("apps") {
      it("should show empty apps screen") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: 1)).to(equal(true))
        expect(app.tables[AccessibilityIdentifiers.Lists.App].cells.count).to(equal(0))
        let addAppLabel = app.staticTexts["Tap + to add a new app"]
        expect(addAppLabel.exists).to(equal(true))
      }

      it("should add a MyElectric app successfully") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: 1)).to(equal(true))
        app.navigationBars["Apps"].buttons["Add"].tap()
        app.sheets["Select a type"].buttons["MyElectric"].tap()

        app.tables.staticTexts["Power Feed"].tap()
        app.tables.staticTexts["use"].tap()

        app.tables.staticTexts["kWh Feed"].tap()
        app.tables.staticTexts["use_kwh"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        expect(app.otherElements[AccessibilityIdentifiers.Apps.MyElectric].waitForExistence(timeout: 1)).to(equal(true))
      }

      it("should add a MySolar app successfully") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: 1)).to(equal(true))
        app.navigationBars["Apps"].buttons["Add"].tap()
        app.sheets["Select a type"].buttons["MySolar"].tap()

        app.tables.staticTexts["Power Feed"].tap()
        app.tables.staticTexts["use"].tap()

        app.tables.staticTexts["Power kWh Feed"].tap()
        app.tables.staticTexts["use_kwh"].tap()

        app.tables.staticTexts["Solar Feed"].tap()
        app.tables.staticTexts["solar"].tap()

        app.tables.staticTexts["Solar kWh Feed"].tap()
        app.tables.staticTexts["solar_kwh"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        expect(app.otherElements[AccessibilityIdentifiers.Apps.MySolar].waitForExistence(timeout: 1)).to(equal(true))
      }

      it("should add a MySolarDivert app successfully") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: 1)).to(equal(true))
        app.navigationBars["Apps"].buttons["Add"].tap()
        app.sheets["Select a type"].buttons["MySolarDivert"].tap()

        app.tables.staticTexts["Power Feed"].tap()
        app.tables.staticTexts["use"].tap()

        app.tables.staticTexts["Power kWh Feed"].tap()
        app.tables.staticTexts["use_kwh"].tap()

        app.tables.staticTexts["Solar Feed"].tap()
        app.tables.staticTexts["solar"].tap()

        app.tables.staticTexts["Solar kWh Feed"].tap()
        app.tables.staticTexts["solar_kwh"].tap()

        app.tables.staticTexts["Divert Feed"].tap()
        app.tables.staticTexts["divert"].tap()

        app.tables.staticTexts["Divert kWh Feed"].tap()
        app.tables.staticTexts["divert_kwh"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        expect(app.otherElements[AccessibilityIdentifiers.Apps.MySolarDivert].waitForExistence(timeout: 1)).to(equal(true))
      }
    }

    describe("feeds") {
      it("should show feeds screen") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Feeds"].tap()
        expect(app.tables[AccessibilityIdentifiers.Lists.Feed].waitForExistence(timeout: 1)).to(equal(true))
        expect(app.tables[AccessibilityIdentifiers.Lists.Feed].cells.count).to(equal(6))
      }
    }

    describe("settings") {
      it("should logout") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Settings"].tap()
        expect(app.tables[AccessibilityIdentifiers.Settings].waitForExistence(timeout: 1)).to(equal(true))
        app.tables[AccessibilityIdentifiers.Settings].staticTexts["Logout"].tap()
        app.sheets.buttons["Logout"].tap()
        expect(app.tables[AccessibilityIdentifiers.Lists.Account].waitForExistence(timeout: 1)).to(equal(true))
        expect(app.tables[AccessibilityIdentifiers.Lists.Account].cells.count).to(equal(0))
      }

      it("should switch account") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Settings"].tap()
        expect(app.tables[AccessibilityIdentifiers.Settings].waitForExistence(timeout: 1)).to(equal(true))
        app.tables[AccessibilityIdentifiers.Settings].staticTexts["Switch Account"].tap()
        expect(app.tables[AccessibilityIdentifiers.Lists.Account].waitForExistence(timeout: 1)).to(equal(true))
        expect(app.tables[AccessibilityIdentifiers.Lists.Account].cells.count).to(equal(1))
      }
    }
  }

}
