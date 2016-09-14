//
//  MainController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

class MainController {

  let window: UIWindow
  let loginController: LoginController
  var api: EmonCMSAPI?

  fileprivate var addAccountViewStack: UINavigationController?
  fileprivate var mainViewStack: UITabBarController?

  init() {
    self.window = UIWindow()
    self.loginController = LoginController()
    self.loginController.delegate = self
  }

  func loadUserInterface() {
    self.setupAPI()
    if self.api != nil {
      self.loadMainUI()
    } else {
      self.loadAddAccountUI()
    }
    self.window.makeKeyAndVisible()
  }

  func login(withAccount account: Account) {
    do {
      try self.loginController.login(withAccount: account)
      self.setupAPI()
      self.loadMainUI()
    } catch {
      let alert = UIAlertController(title: "Error", message: "Login failed. Please try again.", preferredStyle: .alert)
      self.window.rootViewController?.present(alert, animated: true, completion: nil)
    }
  }

  func logout() {
    do {
      try self.loginController.logout()
      self.setupAPI()
      self.loadAddAccountUI()
    } catch {
      let alert = UIAlertController(title: "Error", message: "Logout failed. Please try again.", preferredStyle: .alert)
      self.window.rootViewController?.present(alert, animated: true, completion: nil)
    }
  }

  private func setupAPI() {
    if let account = loginController.account {
      self.api = EmonCMSAPI(account: account)
    } else {
      self.api = nil
    }
  }

  private func loadMainUI() {
    guard let api = self.api else {
      print("Tried to load main UI, but no account set yet!")
      return
    }

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let rootViewController = storyboard.instantiateInitialViewController() as! UITabBarController
    self.mainViewStack = rootViewController

    // Setup view models

    let tabBarViewControllers = rootViewController.viewControllers!

    let feedListNavController = tabBarViewControllers[0] as! UINavigationController
    let feedListViewController = feedListNavController.topViewController! as! FeedListViewController
    feedListViewController.viewModel = FeedListViewModel(api: api)

    let settingsNavController = tabBarViewControllers[1] as! UINavigationController
    let settingsViewController = settingsNavController.topViewController! as! SettingsViewController
    settingsViewController.delegate = self
    settingsViewController.viewModel = SettingsViewModel(api: api)

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
    addAccountViewController.viewModel = AddAccountViewModel()
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

extension MainController: LoginControllerDelegate {

}
