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
    if let indexPath = self.tableView.indexPathForSelectedRow {
      self.tableView.deselectRow(at: indexPath, animated: true)
    }
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
        let labelRow = LabelRowFormer<FormLabelCell>()
          .configure { [weak self] in
            guard let strongSelf = self else { return }
            $0.text = field.name
            $0.subText = strongSelf.data[field.id] as? String
        }
        self.setupFeedCellBindings(forRow: labelRow, field: feedField)
        row = labelRow
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

  private func setupFeedCellBindings(forRow row: LabelRowFormer<FormLabelCell>, field: AppConfigFieldFeed) {
    let selectedFeed = Observable<()>.create { observer in
        row.onSelected { _ in
          observer.onNext(())
        }
        return Disposables.create()
      }
      .flatMap { [weak self] _ -> Driver<String?> in
        guard let strongSelf = self else { return Driver.empty() }

        let viewController = AppSelectFeedViewController()
        viewController.viewModel = strongSelf.viewModel.feedListViewModel()
        strongSelf.navigationController?.pushViewController(viewController, animated: true)

        return viewController.finished
      }
      .do(onNext: { [weak self] selectedFeed in
        guard let strongSelf = self else { return }

        if let selectedFeed = selectedFeed {
          strongSelf.data[field.id] = selectedFeed
        }

        strongSelf.navigationController?.popViewController(animated: true)
      })
      .startWith(self.data[field.id] as? String)

    let feeds = self.viewModel.feedListHelper.feeds.asObservable().startWith([])

    Observable.combineLatest(feeds, selectedFeed)
      .asDriver(onErrorJustReturn: ([], nil))
      .drive(onNext: { feeds, selectedFeedId in
        row.update { row in
          if
            let selectedFeedId = selectedFeedId,
            let feed = feeds.first(where: { $0.feedId == selectedFeedId })
          {
            row.subText = feed.name
          } else {
            row.subText = "-- Select a feed --"
          }
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
              if let error = error as? AppConfigViewModel.SaveError {
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
