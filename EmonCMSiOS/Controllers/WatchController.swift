//
//  WatchController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import WatchConnectivity

import RxSwift

class WatchController: NSObject {

  private let loginController: LoginController

  private let disposeBag = DisposeBag()

  // Inputs
  let complicationFeedId = Variable<String?>(nil)

  private enum UserDefaultKeys: String {
    case complicationFeedId
  }

  var isPaired: Bool {
    let session = WCSession.default()
    if session.activationState == .activated {
      return session.isPaired
    }
    return false
  }

  var isWatchAppInstalled: Bool {
    let session = WCSession.default()
    if session.activationState == .activated {
      return session.isWatchAppInstalled
    }
    return false
  }

  init(loginController: LoginController) {
    self.loginController = loginController
    super.init()
  }

  func initialise() {
    self.setupWatchSession()
    self.setupBindings()
  }

  private func setupWatchSession() {
    if WCSession.isSupported() {
      let watchSession = WCSession.default()
      watchSession.delegate = self
      watchSession.activate()
    }
  }

  private func setupBindings() {
    guard WCSession.isSupported() else { return }

    if let complicationFeedId = UserDefaults.standard.string(forKey: UserDefaultKeys.complicationFeedId.rawValue) {
      self.complicationFeedId.value = complicationFeedId
    }

    self.complicationFeedId
      .asObservable()
      .subscribe(onNext: { [weak self] feedId in
        guard let strongSelf = self else { return }
        if let feedId = feedId {
          UserDefaults.standard.set(feedId, forKey: UserDefaultKeys.complicationFeedId.rawValue)
        } else {
          UserDefaults.standard.removeObject(forKey: UserDefaultKeys.complicationFeedId.rawValue)
        }
        strongSelf.pushApplicationContextToWatch()
      })
      .addDisposableTo(self.disposeBag)
  }

  private func applicationContext() -> [String:Any] {
    var result: [String:Any] = [:]

    if let complicationFeedId = UserDefaults.standard.string(forKey: UserDefaultKeys.complicationFeedId.rawValue) {
      result[WatchConstants.ApplicationContextKeys.complicationFeedId.rawValue] = complicationFeedId
    }

    if let account = self.loginController.account {
      result[WatchConstants.ApplicationContextKeys.accountUUID.rawValue] = account.uuid.uuidString
      result[WatchConstants.ApplicationContextKeys.accountURL.rawValue] = account.url
      result[WatchConstants.ApplicationContextKeys.accountApiKey.rawValue] = account.apikey
    }

    return result
  }

  fileprivate func pushApplicationContextToWatch() {
    let session = WCSession.default()
    guard session.activationState == .activated else { return }

    do {
      try session.updateApplicationContext(self.applicationContext())
    } catch {
      AppLog.error("Failed to update watch application context: \(error)")
    }
  }

}

extension WatchController: WCSessionDelegate {

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Swift.Error?) {
    if let error = error {
      AppLog.error("Watch session activation failed: \(error)")
    } else {
      self.pushApplicationContextToWatch()
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
  }

  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

}
