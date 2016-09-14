//
//  SettingsViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: class {
  func settingsViewControllerDidRequestLogout(controller: SettingsViewController)
}

class SettingsViewController: UIViewController {

  var viewModel: SettingsViewModel!

  weak var delegate: SettingsViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Settings"
  }

  @IBAction private func logout() {
    self.delegate?.settingsViewControllerDidRequestLogout(controller: self)
  }

}
