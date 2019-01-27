//
//  AppDelegate.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 11/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

  let mainController: MainController

  #if DEBUG
  private static func isRunningTests() -> Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
  }

  private static func isRunningUITests() -> Bool {
    return CommandLine.arguments.contains("--uitesting")
  }
  #else
  private static func isRunningTests() -> Bool { return false }
  private static func isRunningUITests() -> Bool { return false }
  #endif

  override init() {
    LogController.shared.initialise()
    self.mainController = MainController()
    super.init()
  }

  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    let runningTests = AppDelegate.isRunningTests()
    let runningUITests = AppDelegate.isRunningUITests()

    if (runningTests && !runningUITests) {
      // Skip initialising the UI if running unit tests
      return true
    }

    let dataDirectory: URL
    let requestProvider: HTTPRequestProvider
    if runningUITests {
      UIView.setAnimationsEnabled(false)
      dataDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("uitests")
      try? FileManager.default.removeItem(at: dataDirectory)
      try! FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true, attributes: nil)

      let config = FakeHTTPProvider.Config(
        startTime: Date(timeIntervalSinceNow: -3600*24),
        feeds: [
          FakeHTTPProvider.Config.Feed(id: "1", name: "use", tag: "Node 5", interval: 10, kwhFeed: ("2", "use_kwh")),
          FakeHTTPProvider.Config.Feed(id: "3", name: "solar", tag: "Node 5", interval: 10, kwhFeed: ("4", "solar_kwh")),
          FakeHTTPProvider.Config.Feed(id: "5", name: "immersion", tag: "Node 5", interval: 10, kwhFeed: ("6", "immersion_kwh")),
        ]
      )
      requestProvider = FakeHTTPProvider(config: config)
    } else {
      dataDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.SharedApplicationGroupIdentifier)!
      requestProvider = NSURLSessionHTTPRequestProvider()
    }

    self.mainController.initialise(dataDirectory: dataDirectory, requestProvider: requestProvider)

    return true
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return true
  }

}

