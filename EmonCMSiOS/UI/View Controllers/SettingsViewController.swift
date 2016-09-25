//
//  SettingsViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

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
    }

    let logoutSection = SectionFormer(rowFormer: logoutRow)
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

}
