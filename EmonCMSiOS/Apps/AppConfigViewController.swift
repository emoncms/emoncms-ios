//
//  AppConfigViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

import Former

final class AppConfigViewController: FormViewController {
  var viewModel: AppConfigViewModel!

  lazy var finished: AnyPublisher<AppUUIDAndCategory?, Never> = {
    self.finishedSubject.eraseToAnyPublisher()
  }()

  private var finishedSubject = PassthroughSubject<AppUUIDAndCategory?, Never>()

  private var data: [String: Any] = [:]

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.data = self.viewModel.configData()

    self.title = "Configure"

    self.setupFormer()
    self.setupNavigation()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.feedListHelper.refresh.send(())
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
          guard let self = self else { return }
          $0.placeholder = field.name
          $0.text = self.data[field.id] as? String
        }.onTextChanged { [weak self] text in
          guard let self = self else { return }
          self.data[field.id] = text
        }
        row = textFieldRow
      case let feedField as AppConfigFieldFeed:
        let labelRow = LabelRowFormer<FormLabelCell>()
          .configure { [weak self] in
            guard let self = self else { return }
            $0.text = field.name
            $0.subText = self.data[field.id] as? String
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
    let selectedFeed = Producer<Void, Never> { observer in
      row.onSelected { _ in
        _ = observer.receive(())
      }
    }
    .flatMap { [weak self] _ -> AnyPublisher<String?, Never> in
      guard let self = self else { return Empty<String?, Never>().eraseToAnyPublisher() }

      let viewController = AppSelectFeedViewController()
      viewController.viewModel = self.viewModel.feedListViewModel()
      self.navigationController?.pushViewController(viewController, animated: true)

      return viewController.finished
    }
    .handleEvents(receiveOutput: { [weak self] selectedFeed in
      guard let self = self else { return }

      if let selectedFeed = selectedFeed {
        self.data[field.id] = selectedFeed
      }

      self.navigationController?.popViewController(animated: true)
      })
    .prepend(self.data[field.id] as? String)

    let feeds = self.viewModel.feedListHelper.$feeds.prepend([])

    Publishers.CombineLatest(feeds, selectedFeed)
      .replaceError(with: ([], nil))
      .sink { [weak self] feeds, selectedFeedId in
        guard let self = self else { return }

        row.update { row in
          row.subText = "-- Select a feed --"

          var actualSelectedFeedId = selectedFeedId
          if actualSelectedFeedId == nil {
            for feed in feeds {
              if feed.name == field.defaultName {
                actualSelectedFeedId = feed.feedId
                self.data[field.id] = actualSelectedFeedId
                break
              }
            }
          }

          if let selectedFeedId = actualSelectedFeedId {
            if let feed = feeds.first(where: { $0.feedId == selectedFeedId }) {
              row.subText = feed.name
            }
          }
        }
      }
      .store(in: &self.cancellables)
  }

  private func setupNavigation() {
    let leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
    self.navigationItem.leftBarButtonItem = leftBarButtonItem
    let cancelTap = leftBarButtonItem.publisher().map { _ in false }

    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
    let saveTap = rightBarButtonItem.publisher().map { _ in true }

    Publishers.Merge(cancelTap, saveTap)
      .map { [weak self] save -> AnyPublisher<AppUUIDAndCategory?, Never> in
        guard let self = self else { return Just<AppUUIDAndCategory?>(nil).eraseToAnyPublisher() }

        if save {
          return self.viewModel.updateWithConfigData(self.data)
            .map { $0 as AppUUIDAndCategory? }
            .catch { [weak self] error -> AnyPublisher<AppUUIDAndCategory?, Never> in
              guard let self = self else { return Empty<AppUUIDAndCategory?, Never>(completeImmediately: false).eraseToAnyPublisher() }

              let message: String
              switch error {
              case .missingFields(let fields):
                let fieldsText = fields.map { $0.name }.joined(separator: "\n")
                message = "Missing fields:\n\(fieldsText)"
              case .generic, .realmFailure:
                message = "A problem occurred."
              }

              let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

              self.present(alert, animated: true, completion: nil)

              return Empty<AppUUIDAndCategory?, Never>(completeImmediately: false).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        }
        return Just<AppUUIDAndCategory?>(nil).eraseToAnyPublisher()
      }
      .switchToLatest()
      .subscribe(self.finishedSubject)
      .store(in: &self.cancellables)
  }
}
