//
//  SettingsViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import MessageUI
import UIKit

import Former

final class SettingsViewController: FormViewController {
  var viewModel: SettingsViewModel!

  lazy var switchAccount: AnyPublisher<Bool, Never> = self.switchAccountSubject.eraseToAnyPublisher()

  private var switchAccountSubject = PassthroughSubject<Bool, Never>()

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Settings"
    self.tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings

    self.setupFormer()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active = false
  }

  private func setupFormer() {
    let logoutRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
    }.configure {
      $0.text = "Logout"
    }.onSelected { [weak self] former in
      guard let self = self else { return }

      let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to logout?",
                                          preferredStyle: .actionSheet)

      actionSheet.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
        self.former.deselect(animated: true)
        if let selectedRow = self.tableView.indexPathForSelectedRow {
          self.tableView.deselectRow(at: selectedRow, animated: true)
        }
        self.switchAccountSubject.send(true)
      }))

      actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        if let selectedRow = self.tableView.indexPathForSelectedRow {
          self.tableView.deselectRow(at: selectedRow, animated: true)
        }
      }))

      if let popoverController = actionSheet.popoverPresentationController {
        popoverController.sourceView = former.cell
        popoverController
          .sourceRect = CGRect(x: former.cell.bounds.midX, y: former.cell.bounds.midY, width: 0, height: 0)
      }

      self.present(actionSheet, animated: true, completion: nil)
    }

    let switchAccountRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
    }.configure {
      $0.text = "Switch Account"
    }.onSelected { [weak self] _ in
      guard let self = self else { return }
      self.switchAccountSubject.send(false)
    }

    let configureTodayWidgetsRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
    }.configure {
      $0.text = "Configure Today Widget"
    }.onSelected { [weak self] _ in
      guard let self = self else { return }
      self.showTodayWidgetsView()
      self.former.deselect(animated: true)
    }

    let feedbackRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
    }.configure {
      $0.text = "Send Feedback"
    }.onSelected { [weak self] _ in
      guard let self = self else { return }
      self.sendFeedback()
      self.former.deselect(animated: true)
    }

    let detailsFooter = LabelViewFormer<FormLabelFooterView>() { _ in
    }.configure {
      let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
      let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
      $0.text = "App Version: \(appVersion) (\(buildNumber))"
    }

    let section1 = SectionFormer(rowFormer: logoutRow, switchAccountRow)
    let section2 = SectionFormer(rowFormer: configureTodayWidgetsRow)
    let section3 = SectionFormer(rowFormer: feedbackRow)
      .set(footerViewFormer: detailsFooter)

    self.former.append(sectionFormer: section1, section2, section3)
  }

  private func sendFeedback() {
    guard MFMailComposeViewController.canSendMail() else {
      let alert = UIAlertController(title: "Can't send mail",
                                    message: "To send feedback you need to be able to send email from this device. Please ensure you have an email account set up.",
                                    preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      self.present(alert, animated: true, completion: nil)
      return
    }

    let mailComposer = MFMailComposeViewController()
    mailComposer.mailComposeDelegate = self
    mailComposer.setToRecipients(["matt@swipestack.com"])
    mailComposer.setSubject("Emoncms iOS feedback")
    mailComposer.setMessageBody("Please enter your feedback below:\n\n", isHTML: false)

    for file in LogController.shared.logFiles {
      do {
        let data = try Data(contentsOf: file)
        mailComposer.addAttachmentData(data, mimeType: "text/plain", fileName: file.lastPathComponent)
      } catch {
        AppLog.error("Failed to read log file at \(file).")
      }
    }

    self.present(mailComposer, animated: true, completion: nil)
  }

  private func showTodayWidgetsView() {
    let viewController = TodayWidgetFeedsListViewController()
    let viewModel = self.viewModel.todayWidgetFeedsListViewModel()
    viewController.viewModel = viewModel
    self.navigationController?.pushViewController(viewController, animated: true)
  }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: Error?)
  {
    self.dismiss(animated: true, completion: nil)
  }
}
