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

  init() {
    self.window = UIWindow()
    self.requestProvider = NSURLSessionHTTPRequestProvider()
    self.api = EmonCMSAPI(requestProvider: self.requestProvider)
  }

  func initialise(dataDirectory: URL) {
    let realmController = RealmController(dataDirectory: dataDirectory)

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let rootViewController = storyboard.instantiateInitialViewController() as! UINavigationController

    let accountListViewController = rootViewController.topViewController! as! AccountListViewController
    accountListViewController.viewModel = AccountListViewModel(realmController: realmController, api: self.api)

    self.window.rootViewController = rootViewController
    self.window.makeKeyAndVisible()
  }

}
