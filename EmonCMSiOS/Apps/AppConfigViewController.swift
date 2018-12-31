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

final class AppConfigViewController: FormViewController {

  var viewModel: AppConfigViewModel!

  lazy var finished: Driver<AppUUIDAndCategory?> = {
    return self.finishedSubject.asDriver(onErrorJustReturn: nil)
  }()
  private var finishedSubject = PublishSubject<AppUUIDAndCategory?>()

  private var data: [String:Any] = [:]

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.data = self.viewModel.configData()

    self.title = "Configure"

    self.setupFormer()
    self.setupNavigation()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.feedListHelper.refresh.onNext(())
  }

  private func setupFormer() {
    var rows: [RowFormer] = []

    for field in self.viewModel.configFields() {
      let row: RowFormer?

      switch field {
      case _ as AppConfigFieldString:
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
      case let feedField as AppConfigFieldFeed:
        let inlinePickerRow = InlinePickerRowFormer<FormInlinePickerCell, FeedListHelper.FeedListItem>() {
          $0.titleLabel.text = field.name
        }
        self.setupFeedListBindings(forRow: inlinePickerRow, field: feedField)
        row = inlinePickerRow
      default:
        AppLog.error("Unhandled app config type: \(field)")
        row = nil
      }

      if let row = row {
        rows.append(row)
      }
    }

    let section = SectionFormer(rowFormers: rows)
    self.former.add(sectionFormers: [section])
  }

  private func setupFeedListBindings(forRow row: InlinePickerRowFormer<FormInlinePickerCell, FeedListHelper.FeedListItem>, field: AppConfigFieldFeed) {
    self.viewModel.feedListHelper.feeds
      .startWith([])
      .drive(onNext: { [weak self] feeds in
        guard let strongSelf = self else { return }

        row.update { row in
          var pickerItems: [InlinePickerItem<FeedListHelper.FeedListItem>] = [InlinePickerItem(title: "-- Select a feed --")]
          var selectedIndex = 0

          if feeds.count > 0 {
            var selectedFeedId: String? = strongSelf.data[field.id] as? String
            for (i, feed) in feeds.enumerated() {
              if let selectedFeedId = selectedFeedId {
                // If we have a selected feed, see if this is it
                if feed.feedId == selectedFeedId {
                  selectedIndex = i + 1
                }
              } else {
                // If we don't have a selected feed, see if this is the default feed, by name
                if feed.name == field.defaultName {
                  selectedIndex = i + 1
                  selectedFeedId = feed.feedId
                }
              }

              pickerItems.append(InlinePickerItem(title: "(\(feed.feedId)) \(feed.name)", value: feed))
            }

            if selectedIndex > 0 {
              strongSelf.data[field.id] = selectedFeedId
            } else {
              strongSelf.data.removeValue(forKey: field.id)
            }
          }

          row.pickerItems = pickerItems
          row.selectedRow = selectedIndex
        }
        })
      .disposed(by: self.disposeBag)

    Observable<FeedListHelper.FeedListItem?>.create { observer in
        row.onValueChanged { item in
          observer.onNext(item.value)
        }
        return Disposables.create()
      }
      .subscribe(onNext: { [weak self] in
        guard let strongSelf = self else { return }
        if let item = $0 {
          strongSelf.data[field.id] = item.feedId
        } else {
          strongSelf.data.removeValue(forKey: field.id)
        }
      })
      .disposed(by: self.disposeBag)
  }

  private func setupNavigation() {
    let leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    self.navigationItem.leftBarButtonItem = leftBarButtonItem
    let cancelTap = leftBarButtonItem.rx.tap.map { false }

    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
    let saveTap = rightBarButtonItem.rx.tap.map { true }

    Observable.of(cancelTap, saveTap)
      .merge()
      .flatMapLatest { [weak self] save -> Observable<AppUUIDAndCategory?> in
        guard let strongSelf = self else { return Observable.just(nil) }

        if save {
          return strongSelf.viewModel.updateWithConfigData(strongSelf.data)
            .map { $0 as AppUUIDAndCategory? }
            .catchError { [weak self] error in
              guard let strongSelf = self else { return Observable.never() }

              let message: String
              if let error = error as? MyElectricAppConfigViewModel.SaveError {
                switch error {
                case .missingFields(let fields):
                  let fieldsText = fields.map { $0.name }.joined(separator: "\n")
                  message = "Missing fields:\n\(fieldsText)"
                }
              } else {
                message = "An unknown error occurred."
                AppLog.error("Unknown error saving app config data: \(error)")
              }

              let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
              
              strongSelf.present(alert, animated: true, completion: nil)
              
              return Observable.never()
          }
        }
        return Observable.just(nil)
      }
      .subscribe(self.finishedSubject)
      .disposed(by: self.disposeBag)
  }

}
