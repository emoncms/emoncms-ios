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

class AppConfigViewController: FormViewController {

  var viewModel: MyElectricAppConfigViewModel!

  lazy var finished: Driver<String?> = {
    return self.finishedSubject.asDriver(onErrorJustReturn: nil)
  }()
  private var finishedSubject = PublishSubject<String?>()

  private var data: [String:Any] = [:]

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.data = self.viewModel.configData()

    self.title = "Configure"

    self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)

    self.setupFormer()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.feedListHelper.refresh.onNext(())
  }

  private func setupFormer() {
    var rows: [RowFormer] = []

    for field in self.viewModel.configFields() {
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
    self.viewModel.feedListHelper.feeds
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
    let cancelTap = leftBarButtonItem.rx.tap.map { false }

    let rightBarButtonItem = self.navigationItem.rightBarButtonItem!
    let saveTap = rightBarButtonItem.rx.tap.map { true }

    Observable.of(cancelTap, saveTap)
      .merge()
      .flatMap { [weak self] save -> Observable<String?> in
        guard let strongSelf = self else { return Observable.just(nil) }
        if save {
          return strongSelf.viewModel.updateWithConfigData(strongSelf.data)
            .map { $0 as String? }
        }
        return Observable.just(nil)
      }
      .catchError { error in
        AppLog.error("Error saving app config data: \(error)")
        return Observable.empty()
      }
      .subscribe(self.finishedSubject)
      .addDisposableTo(self.disposeBag)
  }

}
