//
//  MainController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

final class MainController {

  private let window: UIWindow
  private let requestProvider: AlamofireHTTPRequestProvider
  private let api: EmonCMSAPI
  private let loginController: LoginController
  private let watchController: WatchController

  fileprivate var addAccountViewStack: UINavigationController?
  fileprivate var mainViewStack: UITabBarController?

  private var disposeBag = DisposeBag()

  init() {
    self.window = UIWindow()
    self.requestProvider = AlamofireHTTPRequestProvider()
    self.api = EmonCMSAPI(requestProvider: self.requestProvider)
    self.loginController = LoginController()
    self.watchController = WatchController(loginController: self.loginController)

    self.watchController.initialise()
  }

  func initialise() {
    let disposeBag = DisposeBag()

    self.loginController.account
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] in
        guard let strongSelf = self else { return }

        if let account = $0 {
          strongSelf.loadMainUI(forAccount: account)
        } else {
          strongSelf.loadAddAccountUI()
        }
      })
      .addDisposableTo(disposeBag)

    self.disposeBag = disposeBag

    self.window.makeKeyAndVisible()
  }

  func login(withAccount account: Account) {
    do {
      try self.loginController.login(withAccount: account)
    } catch {
      let alert = UIAlertController(title: "Error", message: "Login failed. Please try again.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.window.rootViewController?.present(alert, animated: true, completion: nil)
    }
  }

  func logout() {
    do {
      try self.loginController.logout()
    } catch {
      let alert = UIAlertController(title: "Error", message: "Logout failed. Please try again.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.window.rootViewController?.present(alert, animated: true, completion: nil)
    }
  }

  private func loadMainUI(forAccount account: Account) {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let rootViewController = storyboard.instantiateInitialViewController() as! UITabBarController
    self.mainViewStack = rootViewController

    // Setup view models

    let tabBarViewControllers = rootViewController.viewControllers!

    let feedListNavController = tabBarViewControllers[0] as! UINavigationController
    let feedListViewController = feedListNavController.topViewController! as! FeedListViewController
    feedListViewController.viewModel = FeedListViewModel(account: account, api: self.api)

    let chartListNavController = tabBarViewControllers[1] as! UINavigationController
    let chartListViewController = chartListNavController.topViewController! as! ChartListViewController
    chartListViewController.viewModel = ChartListViewModel(account: account, api: self.api)

    let settingsNavController = tabBarViewControllers[2] as! UINavigationController
    let settingsViewController = settingsNavController.topViewController! as! SettingsViewController
    settingsViewController.delegate = self
    settingsViewController.viewModel = SettingsViewModel(account: account, api: self.api, watchController: self.watchController)

    self.window.rootViewController = rootViewController

    if let vc = self.addAccountViewStack {
      let screenshotViewController = ScreenshotViewController(viewToScreenshot: vc.view)
      rootViewController.present(screenshotViewController, animated: false) {
        rootViewController.dismiss(animated: true) {
          self.addAccountViewStack = nil
        }
      }
    }
  }

  private func loadAddAccountUI() {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let rootViewController = storyboard.instantiateViewController(withIdentifier: "AddAccountFlow") as! UINavigationController
    self.addAccountViewStack = rootViewController

    // Setup view models
    let addAccountViewController = rootViewController.topViewController! as! AddAccountViewController
    addAccountViewController.viewModel = AddAccountViewModel(api: self.api)
    addAccountViewController.delegate = self

    if let vc = self.mainViewStack {
      vc.present(rootViewController, animated: true) {
        self.window.rootViewController = rootViewController
        self.mainViewStack = nil
      }
    } else {
      self.window.rootViewController = rootViewController
    }
  }

}

extension MainController: AddAccountViewControllerDelegate {

  func addAccountViewController(controller: AddAccountViewController, didFinishWithAccount account: Account) {
    self.login(withAccount: account)
  }

}

extension MainController: SettingsViewControllerDelegate {

  func settingsViewControllerDidRequestLogout(controller: SettingsViewController) {
    self.logout()
  }

}
