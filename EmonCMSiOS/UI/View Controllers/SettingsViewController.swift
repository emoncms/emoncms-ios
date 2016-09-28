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

protocol SettingsViewControllerDelegate: class {

  func settingsViewControllerDidRequestLogout(controller: SettingsViewController)

}

class SettingsViewController: FormViewController {

  var viewModel: SettingsViewModel!

  weak var delegate: SettingsViewControllerDelegate?

  private var watchFeedRow: InlinePickerRowFormer<FormInlinePickerCell, SettingsViewModel.FeedListItem>!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Settings"

    self.setupFormer()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active.value = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active.value = false
  }

  private func setupFormer() {
    var sections: [SectionFormer] = []

    let logoutRow = LabelRowFormer<FormLabelCell>() {
      $0.accessoryType = .disclosureIndicator
      }.configure {
        $0.text = "Logout"
      }.onSelected { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.delegate?.settingsViewControllerDidRequestLogout(controller: strongSelf)
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

    let logoutSection = SectionFormer(rowFormer: logoutRow, feedbackRow)
      .set(footerViewFormer: detailsFooter)
    sections.append(logoutSection)

    if self.viewModel.showWatchSection {
      let watchFeedRow = InlinePickerRowFormer<FormInlinePickerCell, SettingsViewModel.FeedListItem>() {
        $0.titleLabel.text = "Complication feed"
      }
      self.watchFeedRow = watchFeedRow

      let watchHeader = LabelViewFormer<FormLabelHeaderView>() { _ in
        }.configure {
          $0.viewHeight = 44
          $0.text = "Apple Watch"
      }

      let watchSection = SectionFormer(rowFormer: watchFeedRow)
        .set(headerViewFormer: watchHeader)
      sections.append(watchSection)
    }

    self.former.add(sectionFormers: sections)
  }

  private func setupBindings() {
    if self.viewModel.showWatchSection {
      self.viewModel.feeds
        .startWith([])
        .drive(onNext: { [weak self] feeds in
          guard let strongSelf = self else { return }

          strongSelf.watchFeedRow.update { row in
            let selectedFeedId = strongSelf.viewModel.watchFeed.value?.feedId ?? "-1"
            var selectedIndex = 0
            var pickerItems: [InlinePickerItem<SettingsViewModel.FeedListItem>] = [InlinePickerItem(title: "-- Select a feed --")]
            for (i, feed) in feeds.enumerated() {
              if feed.feedId == selectedFeedId {
                selectedIndex = i + 1
              }
              pickerItems.append(InlinePickerItem(title: "(\(feed.feedId)) \(feed.name)", value: feed))
            }
            row.pickerItems = pickerItems
            row.selectedRow = selectedIndex
          }
          })
        .addDisposableTo(self.disposeBag)

      Observable<SettingsViewModel.FeedListItem?>.create { observer in
        let row = self.watchFeedRow
        row?.onValueChanged { item in
          if let value = item.value {
            observer.onNext(value)
          }
        }
        return Disposables.create()
      }
        .bindTo(self.viewModel.watchFeed)
        .addDisposableTo(self.disposeBag)
    }
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

}

extension SettingsViewController: MFMailComposeViewControllerDelegate {

  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    self.dismiss(animated: true, completion: nil)
  }

}
