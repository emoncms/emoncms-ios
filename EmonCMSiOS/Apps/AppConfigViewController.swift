//
//  AppConfigViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import Former
import RxSwift
import RxCocoa

protocol AppConfigViewControllerDelegate: class {

  func appConfigViewControllerDidCancel(_ viewController: AppConfigViewController)
  func appConfigViewController(_ viewController: AppConfigViewController, didFinishWithData data: [String:Any])

}

class AppConfigViewController: FormViewController {

  weak var delegate: AppConfigViewControllerDelegate?

  private let fields: [AppConfigField]
  private var data: [String:Any]
  private let feedListHelper: FeedListHelper

  private let disposeBag = DisposeBag()

  init(fields: [AppConfigField], data: [String:Any], feedListHelper: FeedListHelper) {
    self.fields = fields
    self.data = data
    self.feedListHelper = feedListHelper
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Configure"

    self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)

    self.setupFormer()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.feedListHelper.refresh.onNext(())
  }

  private func setupFormer() {
    var rows: [RowFormer] = []

    for field in self.fields {
      let row: RowFormer

      switch field.type {
      case .string:
        let textFieldRow = TextFieldRowFormer<FormTextFieldCell>() {
          $0.titleLabel.text = field.name
          $0.textField.textAlignment = .right
          }.configure { [weak self] in
            guard let strongSelf = self else { return }
            $0.placeholder = field.name
            $0.text = strongSelf.data[field.id] as? String
          }.onTextChanged { [weak self] text in
            guard let strongSelf = self else { return }
            strongSelf.data[field.id] = text
        }
        row = textFieldRow
      case .feed:
        let inlinePickerRow = InlinePickerRowFormer<FormInlinePickerCell, FeedListHelper.FeedListItem>() {
          $0.titleLabel.text = field.name
        }
        self.setupFeedListBindings(forRow: inlinePickerRow, fieldId: field.id)
        row = inlinePickerRow
      }

      rows.append(row)
    }

    let section = SectionFormer(rowFormers: rows)
    self.former.add(sectionFormers: [section])
  }

  private func setupFeedListBindings(forRow row: InlinePickerRowFormer<FormInlinePickerCell, FeedListHelper.FeedListItem>, fieldId: String) {
    self.feedListHelper.feeds
      .startWith([])
      .drive(onNext: { [weak self] feeds in
        guard let strongSelf = self else { return }

        row.update { row in
          let selectedFeedId = (strongSelf.data[fieldId] as? String) ?? "-1"
          var selectedIndex = 0
          var pickerItems: [InlinePickerItem<FeedListHelper.FeedListItem>] = [InlinePickerItem(title: "-- Select a feed --")]
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

    Observable<FeedListHelper.FeedListItem>.create { observer in
      row.onValueChanged { item in
        if let value = item.value {
          observer.onNext(value)
        }
      }
      return Disposables.create()
      }
      .subscribe(onNext: { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.data[fieldId] = $0.feedId
      })
      .addDisposableTo(self.disposeBag)
  }

  private func setupBindings() {
    let leftBarButtonItem = self.navigationItem.leftBarButtonItem!
    leftBarButtonItem.rx.tap
      .subscribe(onNext: { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.delegate?.appConfigViewControllerDidCancel(strongSelf)
        })
      .addDisposableTo(self.disposeBag)

    let rightBarButtonItem = self.navigationItem.rightBarButtonItem!
    rightBarButtonItem.rx.tap
      .subscribe(onNext: { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.delegate?.appConfigViewController(strongSelf, didFinishWithData: strongSelf.data)
        })
      .addDisposableTo(self.disposeBag)
  }

}
