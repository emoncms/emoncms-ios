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

extension XCUIElement {

  func clearAndEnterText(text: String) {
    guard let stringValue = self.value as? String else {
      XCTFail("Tried to clear and enter text into a non string value")
      return
    }

    self.tap()
    let deleteString = stringValue.map { _ in XCUIKeyboardKey.delete.rawValue }.joined()
    self.typeText(deleteString)
    self.typeText(text)
  }

}

class EmonCMSiOSUITests: QuickSpec {

  static let WaitTimeout: TimeInterval = 5

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
      tablesQuery.textFields.element(boundBy: 0).clearAndEnterText(text: name)
      tablesQuery.textFields.element(boundBy: 1).clearAndEnterText(text: url)
      tablesQuery.textFields.element(boundBy: 3).clearAndEnterText(text: apiKey)

      app.navigationBars["Account Details"].buttons["Save"].tap()
    }

    func loginFromAccountListWithValidCredentials() {
      loginFromAccountList(name: "Test Instance", url: "https://localhost", apiKey: "ilikecats")
    }

    describe("accounts") {
      it("should show empty accounts screen") {
        let accountsTable = app.tables[AccessibilityIdentifiers.Lists.Account]
        expect(accountsTable.exists).to(equal(true))
        expect(accountsTable.cells.count).to(equal(0))
        let addAccountLabel = app.staticTexts["Tap + to add a new account"]
        expect(addAccountLabel.exists).to(equal(true))
      }

      it("should add account successfully for valid details") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }

      it("should error for invalid credentials") {
        loginFromAccountList(name: "Test Instance", url: "https://localhost", apiKey: "notthekey")
        expect(app.alerts["Error"].exists).to(equal(true))
      }

      it("should show QR view and then cancel properly") {
        app.navigationBars["Accounts"].buttons["Add"].tap()
        app.tables.cells.staticTexts["Scan QR Code"].tap()
        expect(app.otherElements[AccessibilityIdentifiers.AddAccountQRView].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        app.navigationBars["Scan Code"].buttons["Cancel"].tap()
        expect(app.staticTexts["Scan QR Code"].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }
    }

    describe("apps") {
      it("should show empty apps screen") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(app.tables[AccessibilityIdentifiers.Lists.App].cells.count).to(equal(0))
        let addAppLabel = app.staticTexts["Tap + to add a new app"]
        expect(addAppLabel.exists).to(equal(true))
      }

      it("should fail to add app if not all fields are selected") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        app.navigationBars["Apps"].buttons["Add"].tap()
        app.sheets["Select a type"].buttons["MySolarDivert"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        expect(app.alerts["Error"].exists).to(equal(true))
      }

      it("should add a MyElectric app successfully") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        app.navigationBars["Apps"].buttons["Add"].tap()
        app.sheets["Select a type"].buttons["MyElectric"].tap()

        app.tables.staticTexts["Power Feed"].tap()
        app.tables.staticTexts["use"].tap()

        app.tables.staticTexts["kWh Feed"].tap()
        app.tables.staticTexts["use_kwh"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        expect(app.otherElements[AccessibilityIdentifiers.Apps.MyElectric].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }

      it("should add a MySolar app successfully") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
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

        expect(app.otherElements[AccessibilityIdentifiers.Apps.MySolar].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }

      it("should add a MySolarDivert app successfully") {
        loginFromAccountListWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
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
        app.tables.staticTexts["immersion"].tap()

        app.tables.staticTexts["Divert kWh Feed"].tap()
        app.tables.staticTexts["immersion_kwh"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        expect(app.otherElements[AccessibilityIdentifiers.Apps.MySolarDivert].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }
    }

    describe("inputs") {
      it("should show inputs screen") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Inputs"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Input]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(tableView.cells.count).to(equal(4))
      }
    }

    describe("dashboards") {
      it("should show dashboards screen") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Dashboards"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Dashboard]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(tableView.cells.count).to(equal(2))
      }
    }

    describe("feeds") {
      it("should show feeds screen") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Feeds"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Feed]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(tableView.cells.count).to(equal(6))
      }

      it("should show feed chart when tapping on a cell") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Feeds"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Feed]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))

        let chartContainer = app.otherElements[AccessibilityIdentifiers.FeedList.ChartContainer]
        let chartContainerClosedY = chartContainer.frame.minY

        tableView.cells.element(boundBy: 0).tap()

        let chartContainerOpenY = chartContainer.frame.minY
        expect(chartContainerOpenY).to(beLessThan(chartContainerClosedY))

        let startPoint1 = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let endPoint1 = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.01))
        startPoint1.press(forDuration: 0, thenDragTo: endPoint1)
        expect(chartContainer.frame.minY).to(equal(chartContainerOpenY))

        let startPoint2 = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let endPoint2 = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 1))
        startPoint2.press(forDuration: 0, thenDragTo: endPoint2)
        expect(chartContainer.frame.minY).to(equal(chartContainerClosedY))
      }

      it("should show feed chart view when tapping on detail disclosure") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Feeds"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Feed]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))

        tableView.cells.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        expect(app.otherElements[AccessibilityIdentifiers.FeedChartView].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }
    }

    describe("settings") {
      it("should logout") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Settings"].tap()

        let settingsTable = app.tables[AccessibilityIdentifiers.Settings]
        expect(settingsTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        settingsTable.staticTexts["Logout"].tap()
        app.sheets.buttons["Logout"].tap()

        let accountTable = app.tables[AccessibilityIdentifiers.Lists.Account]
        expect(accountTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(accountTable.cells.count).to(equal(0))
      }

      it("should switch account") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Settings"].tap()

        let settingsTable = app.tables[AccessibilityIdentifiers.Settings]
        expect(settingsTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        settingsTable.staticTexts["Switch Account"].tap()

        let accountTable = app.tables[AccessibilityIdentifiers.Lists.Account]
        expect(accountTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(accountTable.cells.count).to(equal(1))
      }

      it("should show today widgets list") {
        loginFromAccountListWithValidCredentials()
        app.tabBars.buttons["Settings"].tap()

        let settingsTable = app.tables[AccessibilityIdentifiers.Settings]
        expect(settingsTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        settingsTable.staticTexts["Configure Today Widget"].tap()

        let todayWidgetFeedTable = app.tables[AccessibilityIdentifiers.Lists.TodayWidgetFeed]
        expect(todayWidgetFeedTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(todayWidgetFeedTable.cells.count).to(equal(0))

        app.navigationBars.buttons["Add"].tap()
        let selectFeedTable = app.tables[AccessibilityIdentifiers.Lists.AppSelectFeed]
        expect(selectFeedTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))

        app.tables.staticTexts["solar"].tap()
        expect(todayWidgetFeedTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(todayWidgetFeedTable.cells.count).to(equal(1))
      }
    }
  }

}
