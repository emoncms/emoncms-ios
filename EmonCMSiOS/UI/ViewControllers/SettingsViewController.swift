//
//  SettingsViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit
import MessageUI

import Former
import RxSwift
import RxCocoa

final class SettingsViewController: FormViewController {

  var viewModel: SettingsViewModel!

  lazy var switchAccount: Driver<Bool> = {
    return self.switchAccountSubject.asDriver(onErrorJustReturn: false)
  }()
  private var switchAccountSubject = PublishSubject<Bool>()

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Settings"
    self.tableView.accessibilityIdentifier = AccessibilityIdentifiers.Settings

    self.setupFormer()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active.accept(false)
  }

  private func setupFormer() {
    let logoutRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Logout"
      }.onSelected { [weak self] _ in
        guard let strongSelf = self else { return }
        let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to logout?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
          strongSelf.former.deselect(animated: true)
          if let selectedRow = strongSelf.tableView.indexPathForSelectedRow {
            strongSelf.tableView.deselectRow(at: selectedRow, animated: true)
          }
          strongSelf.switchAccountSubject.onNext(true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
          if let selectedRow = strongSelf.tableView.indexPathForSelectedRow {
            strongSelf.tableView.deselectRow(at: selectedRow, animated: true)
          }
        }))
        strongSelf.present(actionSheet, animated: true, completion: nil)
    }

    let switchAccountRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Switch Account"
      }.onSelected { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.switchAccountSubject.onNext(false)
    }

    let configureTodayWidgetsRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Configure Today Widget"
      }.onSelected { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.showTodayWidgetsView()
        strongSelf.former.deselect(animated: true)
    }

    let feedbackRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Send Feedback"
      }.onSelected { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.sendFeedback()
        strongSelf.former.deselect(animated: true)
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
      let alert = UIAlertController.init(title: "Can't send mail", message: "To send feedback you need to be able to send email from this device. Please ensure you have an email account set up.", preferredStyle: .alert)
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
        let data = try Data.init(contentsOf: file)
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

  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    self.dismiss(animated: true, completion: nil)
  }

}
