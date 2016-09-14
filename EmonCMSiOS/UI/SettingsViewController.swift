//
//  SettingsViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import Former

protocol SettingsViewControllerDelegate: class {

  func settingsViewControllerDidRequestLogout(controller: SettingsViewController)

}

class SettingsViewController: FormViewController {

  var viewModel: SettingsViewModel!

  weak var delegate: SettingsViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Settings"

    self.setupFormer()
  }

  private func setupFormer() {
    let logoutRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Logout"
      }.onSelected { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.delegate?.settingsViewControllerDidRequestLogout(controller: strongSelf)
    }

    let section = SectionFormer(rowFormer: logoutRow)
    former.append(sectionFormer: section)
  }

}
