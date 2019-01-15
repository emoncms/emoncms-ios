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
  private let requestProvider: HTTPRequestProvider
  private let api: EmonCMSAPI
  private let realmController: RealmController

  init() {
    self.window = UIWindow()
    self.requestProvider = NSURLSessionHTTPRequestProvider()
    self.api = EmonCMSAPI(requestProvider: self.requestProvider)
    self.realmController = RealmController()
  }

  func initialise() {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let rootViewController = storyboard.instantiateInitialViewController() as! UINavigationController

    let accountListViewController = rootViewController.topViewController! as! AccountListViewController
    accountListViewController.viewModel = AccountListViewModel(realmController: self.realmController, api: self.api)

    self.window.rootViewController = rootViewController
    self.window.makeKeyAndVisible()
  }

}
