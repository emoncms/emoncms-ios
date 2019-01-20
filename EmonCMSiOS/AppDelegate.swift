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

  private static func isRunningTests() -> Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
  }

  private static func isRunningUITests() -> Bool {
    return CommandLine.arguments.contains("--uitesting")
  }

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
      dataDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("uitests")
      try? FileManager.default.removeItem(at: dataDirectory)
      try! FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: false, attributes: nil)
      requestProvider = FakeHTTPProvider()
    } else {
      dataDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.openenergymonitor.emoncms")!
      requestProvider = NSURLSessionHTTPRequestProvider()
    }

    self.mainController.initialise(dataDirectory: dataDirectory, requestProvider: requestProvider)

    return true
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return true
  }

}

