//
//  EmonCMSiOSUITests.swift
//  EmonCMSiOSUITests
//
//  Created by Matt Galloway on 20/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Foundation
import Nimble
import Quick
import XCTest

extension XCUIElement {
  func clearAndEnterText(text: String) {
    guard let stringValue = self.value as? String else {
      XCTFail("Tried to clear and enter text into a non string value")
      return
    }

    self.tap()
    let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
    self.typeText(deleteString)
    self.typeText(text)
  }
}

class EmonCMSiOSUITests: QuickSpec {
  static let WaitTimeout: TimeInterval = 10

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

    func loginFromAppStart(name: String, url: String, apiKey: String) {
      let tablesQuery = app.tables
      tablesQuery.textFields.element(boundBy: 0).clearAndEnterText(text: name)
      tablesQuery.textFields.element(boundBy: 1).clearAndEnterText(text: url)
      tablesQuery.textFields.element(boundBy: 3).clearAndEnterText(text: apiKey)

      app.navigationBars["Account Details"].buttons["Save"].tap()
    }

    func loginFromAppStartWithValidCredentials() {
      loginFromAppStart(name: "Test Instance", url: "https://localhost", apiKey: "ilikecats")
    }

    describe("accounts") {
      it("should show empty accounts screen") {
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let accountsTable = app.tables[AccessibilityIdentifiers.Lists.Account]
        expect(accountsTable.exists).to(equal(true))
        expect(accountsTable.cells.count).to(equal(0))

        let addAccountLabel = app.staticTexts["Tap + to add a new account"]
        expect(addAccountLabel.exists).to(equal(true))
      }

      it("should add account successfully for valid details") {
        loginFromAppStartWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }

      it("should error for invalid credentials") {
        loginFromAppStart(name: "Test Instance", url: "https://localhost", apiKey: "notthekey")
        expect(app.alerts["Error"].exists).to(equal(true))
      }

      it("should show QR view and then cancel properly") {
        app.tables.cells.staticTexts["Scan QR Code"].tap()
        expect(app.otherElements[AccessibilityIdentifiers.AddAccountQRView].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        app.navigationBars["Scan Code"].buttons["Cancel"].tap()
        expect(app.staticTexts["Scan QR Code"].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }

      it("should edit account successfully") {
        loginFromAppStartWithValidCredentials()
        app.tabBars.buttons["Settings"].tap()
        app.tables[AccessibilityIdentifiers.Settings].staticTexts["Switch Account"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        let accountTable = app.tables[AccessibilityIdentifiers.Lists.Account]
        accountTable.cells.element(boundBy: 0).tap()

        expect(app.tables.textFields.element(boundBy: 0).value as? String).to(equal("Test Instance"))
        expect(app.tables.textFields.element(boundBy: 1).value as? String).to(equal("https://localhost"))
        expect(app.tables.textFields.element(boundBy: 3).value as? String).to(equal("ilikecats"))

        app.tables.textFields.element(boundBy: 0).clearAndEnterText(text: "New Name")

        app.navigationBars.buttons["Save"].tap()

        expect(accountTable.cells.staticTexts["New Name"].exists).to(equal(true))
      }
    }

    describe("apps") {
      it("should show empty apps screen") {
        loginFromAppStartWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(app.tables[AccessibilityIdentifiers.Lists.App].cells.count).to(equal(0))
        let addAppLabel = app.staticTexts["Tap + to add a new app"]
        expect(addAppLabel.exists).to(equal(true))
      }

      it("should fail to add app if not all fields are selected") {
        loginFromAppStartWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        app.navigationBars["Apps"].buttons["Add"].tap()
        app.sheets["Select a type"].buttons["MySolarDivert"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        expect(app.alerts["Error"].exists).to(equal(true))
      }

      it("should add a MyElectric app successfully") {
        loginFromAppStartWithValidCredentials()
        expect(app.tables[AccessibilityIdentifiers.Lists.App].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        app.navigationBars["Apps"].buttons["Add"].tap()
        app.sheets["Select a type"].buttons["MyElectric"].tap()

        app.tables.staticTexts["Power Feed"].tap()
        app.tables.staticTexts["use"].tap()

        app.tables.staticTexts["kWh Feed"].tap()
        app.tables.staticTexts["use_kwh"].tap()

        app.navigationBars["Configure"].buttons["Save"].tap()

        let viewQuery = app.otherElements[AccessibilityIdentifiers.Apps.MyElectric]
        expect(viewQuery.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))

        viewQuery.segmentedControls.buttons["1h"].tap()
        viewQuery.segmentedControls.buttons["8h"].tap()
        viewQuery.segmentedControls.buttons["D"].tap()
        viewQuery.segmentedControls.buttons["M"].tap()
        viewQuery.segmentedControls.buttons["Y"].tap()
      }

      it("should add a MySolar app successfully") {
        loginFromAppStartWithValidCredentials()
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

        let viewQuery = app.otherElements[AccessibilityIdentifiers.Apps.MySolar]
        expect(viewQuery.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))

        viewQuery.segmentedControls.buttons["1h"].tap()
        viewQuery.segmentedControls.buttons["8h"].tap()
        viewQuery.segmentedControls.buttons["D"].tap()
        viewQuery.segmentedControls.buttons["M"].tap()
        viewQuery.segmentedControls.buttons["Y"].tap()

        let startPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.5))
        let endPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
      }

      it("should add a MySolarDivert app successfully") {
        loginFromAppStartWithValidCredentials()
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

        let viewQuery = app.otherElements[AccessibilityIdentifiers.Apps.MySolarDivert]
        expect(viewQuery.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))

        viewQuery.segmentedControls.buttons["1h"].tap()
        viewQuery.segmentedControls.buttons["8h"].tap()
        viewQuery.segmentedControls.buttons["D"].tap()
        viewQuery.segmentedControls.buttons["M"].tap()
        viewQuery.segmentedControls.buttons["Y"].tap()

        let startPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 0.5))
        let endPoint = app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
      }
    }

    describe("inputs") {
      it("should show inputs screen") {
        loginFromAppStartWithValidCredentials()
        app.tabBars.buttons["Inputs"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Input]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(tableView.cells.count).to(equal(4))
      }
    }

    describe("dashboards") {
      it("should show dashboards screen") {
        loginFromAppStartWithValidCredentials()
        app.tabBars.buttons["Dashboards"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Dashboard]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(tableView.cells.count).to(equal(2))
      }
    }

    describe("feeds") {
      it("should show feeds screen") {
        loginFromAppStartWithValidCredentials()
        app.tabBars.buttons["Feeds"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Feed]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(tableView.cells.count).to(equal(6))
      }

      it("should show feed chart when tapping on a cell") {
        loginFromAppStartWithValidCredentials()
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
        expect(chartContainer.frame.minY).toEventually(equal(chartContainerOpenY), timeout: EmonCMSiOSUITests.WaitTimeout)

        let startPoint2 = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let endPoint2 = chartContainer.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 1))
        startPoint2.press(forDuration: 0, thenDragTo: endPoint2)
        expect(chartContainer.frame.minY).toEventually(equal(chartContainerClosedY), timeout: EmonCMSiOSUITests.WaitTimeout)
      }

      it("should show feed chart view when tapping on detail disclosure") {
        loginFromAppStartWithValidCredentials()
        app.tabBars.buttons["Feeds"].tap()

        let tableView = app.tables[AccessibilityIdentifiers.Lists.Feed]
        expect(tableView.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))

        tableView.cells.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        expect(app.otherElements[AccessibilityIdentifiers.FeedChartView].waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
      }
    }

    describe("settings") {
      it("should logout") {
        loginFromAppStartWithValidCredentials()
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
        loginFromAppStartWithValidCredentials()
        app.tabBars.buttons["Settings"].tap()

        let settingsTable = app.tables[AccessibilityIdentifiers.Settings]
        expect(settingsTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        settingsTable.staticTexts["Switch Account"].tap()

        let accountTable = app.tables[AccessibilityIdentifiers.Lists.Account]
        expect(accountTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(accountTable.cells.count).to(equal(1))
      }

      it("should show today widgets list") {
        loginFromAppStartWithValidCredentials()
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

        app.navigationBars.buttons["Add"].tap()
        app.tables.staticTexts["solar"].tap()
        expect(todayWidgetFeedTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(todayWidgetFeedTable.cells.count).to(equal(1))

        app.navigationBars.buttons["Add"].tap()
        app.tables.staticTexts["use"].tap()
        expect(todayWidgetFeedTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(todayWidgetFeedTable.cells.count).to(equal(2))

        app.navigationBars.buttons["Add"].tap()
        app.tables.staticTexts["immersion"].tap()
        expect(todayWidgetFeedTable.waitForExistence(timeout: EmonCMSiOSUITests.WaitTimeout)).to(equal(true))
        expect(todayWidgetFeedTable.cells.count).to(equal(3))

        let solar = app.tables.staticTexts["solar"]
        let use = app.tables.staticTexts["use"]
        let immersion = app.tables.staticTexts["immersion"]

        expect(solar.frame.minY).to(beLessThan(use.frame.minY))
        expect(use.frame.minY).to(beLessThan(immersion.frame.minY))

        app.navigationBars.buttons["Edit"].tap()
        let reorderSolar = app.tables.buttons["Reorder solar, Test Instance"]
        let reorderUse = app.tables.buttons["Reorder use, Test Instance"]
        let reorderImmersion = app.tables.buttons["Reorder immersion, Test Instance"]

        reorderImmersion.press(forDuration: 0.5, thenDragTo: reorderSolar)
        expect(immersion.frame.minY).to(beLessThan(solar.frame.minY))
        expect(solar.frame.minY).to(beLessThan(use.frame.minY))

        reorderSolar.press(forDuration: 0.5, thenDragTo: reorderUse)
        expect(immersion.frame.minY).to(beLessThan(use.frame.minY))
        expect(use.frame.minY).to(beLessThan(solar.frame.minY))

        let deleteUse = app.tables.buttons["Delete immersion, Test Instance"]
        deleteUse.tap()
        app.tables.buttons["Delete"].tap()
        expect(todayWidgetFeedTable.cells.count).to(equal(2))
      }
    }
  }
}
