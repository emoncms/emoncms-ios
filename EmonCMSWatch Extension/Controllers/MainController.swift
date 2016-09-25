//
//  MainController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 25/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import WatchKit
import WatchConnectivity

final class MainController: NSObject {

  private let requestProvider: AlamofireHTTPRequestProvider
  private let api: EmonCMSAPI
  let loginController: LoginController

  private enum InterfaceIdentifiers: String {
    case loginRequiredInterface
    case feedsInterface
  }

  override init() {
    self.requestProvider = AlamofireHTTPRequestProvider()
    self.api = EmonCMSAPI(requestProvider: self.requestProvider)
    self.loginController = LoginController()

    super.init()

    if WCSession.isSupported() {
      let watchSession = WCSession.default()
      watchSession.delegate = self
      watchSession.activate()
    }
  }

  func complicationViewModel() -> ComplicationViewModel {
    return ComplicationViewModel(account: self.loginController.account)
  }

  func applicationDidFinishLaunching() {
    self.initialiseUI()
  }

  private func initialiseUI() {
    // Check that we have a UI. If not, don't bother doing anything just yet. We will when the app launches int the foreground.
    guard WKExtension.shared().applicationState == .active else { return }

    if let account = self.loginController.account {
      let name = InterfaceIdentifiers.feedsInterface.rawValue
      let viewModel = FeedListViewModel(account: account, api: self.api)
      WKInterfaceController.reloadRootControllers(withNames: [name], contexts: [viewModel])
    } else {
      let name = InterfaceIdentifiers.loginRequiredInterface.rawValue
      WKInterfaceController.reloadRootControllers(withNames: [name], contexts: nil)
    }
  }

  fileprivate func updateFromApplicationContext(_ applicationContext: [String:Any]) {
    if
      let uuidString = applicationContext[WatchConstants.ApplicationContextKeys.accountUUID.rawValue] as? String,
      let uuid = UUID(uuidString: uuidString),
      let url = applicationContext[WatchConstants.ApplicationContextKeys.accountURL.rawValue] as? String,
      let apikey = applicationContext[WatchConstants.ApplicationContextKeys.accountApiKey.rawValue] as? String
    {
      do {
        let account = Account(uuid: uuid, url: url, apikey: apikey)
        try self.loginController.login(withAccount: account)
      } catch {
        print("Error logging in on watch: \(error)")
      }
    }

    DispatchQueue.main.async {
      self.initialiseUI()
    }
  }

}

extension MainController: WCSessionDelegate {

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Swift.Error?) {
    if let error = error {
      print("Watch session activation failed: \(error)")
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    self.updateFromApplicationContext(applicationContext)
  }

}
