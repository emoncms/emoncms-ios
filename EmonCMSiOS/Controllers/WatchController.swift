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
  private var applicationContextDisposable: Disposable?

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
  }

  private func setupWatchSession() {
    if WCSession.isSupported() {
      let watchSession = WCSession.default()
      watchSession.delegate = self
      watchSession.activate()
    }
  }

  fileprivate func setupApplicationContextBinding() {
    guard WCSession.isSupported() else { return }

    let applicationContext: Observable<[String:Any]> = self.loginController.account
      .map { account in
        var result: [String:Any] = [:]
        if let account = account {
          result[SharedConstants.ApplicationContextKeys.accountUUID.rawValue] = account.uuid.uuidString
          result[SharedConstants.ApplicationContextKeys.accountURL.rawValue] = account.url
          result[SharedConstants.ApplicationContextKeys.accountApiKey.rawValue] = account.apikey
        }
        return result
    }

    let watchSessionState = WCSession.default().rx.observe(WCSessionActivationState.self, "activationState")
      .distinctUntilChanged { $0 == $1 }
      .filter { $0 == .activated }

    self.applicationContextDisposable = Observable
      .combineLatest(applicationContext, watchSessionState) { applicationContext, _ in
        return applicationContext
      }
      .subscribe(onNext: { applicationContext in
        do {
          let session = WCSession.default()
          try session.updateApplicationContext(applicationContext)
        } catch {
          AppLog.error("Failed to update watch application context: \(error)")
        }
      })
  }

}

extension WatchController: WCSessionDelegate {

  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Swift.Error?) {
    if let error = error {
      AppLog.error("Watch session activation failed: \(error)")
    } else {
      self.setupApplicationContextBinding()
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
  }

  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }

}
