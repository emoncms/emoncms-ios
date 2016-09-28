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

import RxSwift
import RxCocoa

final class MainController: NSObject {

  private let requestProvider: AlamofireHTTPRequestProvider
  private let api: EmonCMSAPI
  private let loginController: LoginController

  let complicationViewModel: ComplicationViewModel

  private var disposeBag = DisposeBag()

  private enum InterfaceIdentifiers: String {
    case loginRequiredInterface
    case feedsInterface
  }

  override init() {
    self.requestProvider = AlamofireHTTPRequestProvider()
    self.api = EmonCMSAPI(requestProvider: self.requestProvider)
    self.loginController = LoginController()
    self.complicationViewModel = ComplicationViewModel(loginController: self.loginController)

    super.init()

    if WCSession.isSupported() {
      let watchSession = WCSession.default()
      watchSession.delegate = self
      watchSession.activate()
    }
  }

  func applicationDidFinishLaunching() {
    self.initialiseUI()
  }

  private func initialiseUI() {
    // Check that we have a UI. If not, don't bother doing anything just yet. We will when the app launches int the foreground.
    guard WKExtension.shared().applicationState == .active else { return }

    let disposeBag = DisposeBag()

    self.loginController.account
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] in
        guard let strongSelf = self else { return }

        if let account = $0 {
          let name = InterfaceIdentifiers.feedsInterface.rawValue
          let viewModel = FeedListViewModel(account: account, api: strongSelf.api)
          WKInterfaceController.reloadRootControllers(withNames: [name], contexts: [viewModel])
        } else {
          let name = InterfaceIdentifiers.loginRequiredInterface.rawValue
          WKInterfaceController.reloadRootControllers(withNames: [name], contexts: nil)
        }
      })
      .addDisposableTo(disposeBag)

    self.disposeBag = disposeBag
  }

  fileprivate func updateFromApplicationContext(_ applicationContext: [String:Any]) {
    if
      let uuidString = applicationContext[SharedConstants.ApplicationContextKeys.accountUUID.rawValue] as? String,
      let uuid = UUID(uuidString: uuidString),
      let url = applicationContext[SharedConstants.ApplicationContextKeys.accountURL.rawValue] as? String,
      let apikey = applicationContext[SharedConstants.ApplicationContextKeys.accountApiKey.rawValue] as? String
    {
      do {
        let account = Account(uuid: uuid, url: url, apikey: apikey)
        try self.loginController.login(withAccount: account)
      } catch {
        AppLog.error("Error logging in on watch: \(error)")
      }
    } else {
      do {
        try self.loginController.logout()
      } catch {
        AppLog.error("Error logging out on watch: \(error)")
      }
    }

    let complicationFeedId = applicationContext[SharedConstants.ApplicationContextKeys.complicationFeedId.rawValue] as? String ?? ""
    self.complicationViewModel.feedId.value = complicationFeedId
  }

}

extension MainController: WCSessionDelegate {

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Swift.Error?) {
    if let error = error {
      AppLog.error("Watch session activation failed: \(error)")
    }
  }

  func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    self.updateFromApplicationContext(applicationContext)
  }

}
