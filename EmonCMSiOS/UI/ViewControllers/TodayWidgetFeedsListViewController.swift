//
//  TodayWidgetFeedsListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

final class TodayWidgetFeedsListViewController: UITableViewController {
  var viewModel: TodayWidgetFeedsListViewModel!

  private var emptyLabel: UILabel?

  private var dataSource: CombineTableViewDataSource<TodayWidgetFeedsListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()
  private var firstLoad = true

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Today Widget Feeds"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Lists.TodayWidgetFeed
    self.navigationItem.largeTitleDisplayMode = .never

    self.tableView.allowsSelection = false

    self.setupDataSource()
    self.setupBindings()
    self.setupNavigation()
  }

  private func setupDataSource() {
    let dataSource = CombineTableViewDataSource<TodayWidgetFeedsListViewModel.Section>(
      configureCell: { _, tableView, _, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ??
          UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = item.feedName
        cell.detailTextLabel?.text = item.accountName
        return cell
      },
      titleForHeaderInSection: { _, _ in "" },
      canEditRowAtIndexPath: { _, _ in true },
      canMoveRowAtIndexPath: { _, _ in true })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$feeds
      .map { [TodayWidgetFeedsListViewModel.Section(model: "", items: $0)] }
      .eraseToAnyPublisher()

    dataSource.assign(toTableView: self.tableView, items: items)
    self.dataSource = dataSource
  }

  private func setupBindings() {
    self.dataSource
      .modelDeleted
      .flatMap { [weak self] item -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty<Void, Never>().eraseToAnyPublisher() }
        return self.viewModel.deleteTodayWidgetFeed(withId: item.todayWidgetFeedId).replaceError(with: ()).eraseToAnyPublisher()
      }
      .sink { _ in }
      .store(in: &self.cancellables)

    self.dataSource
      .itemMoved
      .flatMap { [weak self] (sourceIndex, destinationIndex) -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty<Void, Never>().eraseToAnyPublisher() }
        return self.viewModel.moveTodayWidgetFeed(fromIndex: sourceIndex.row, toIndex: destinationIndex.row).replaceError(with: ()).eraseToAnyPublisher()
      }
      .sink { _ in }
      .store(in: &self.cancellables)

    self.viewModel.$feeds
      .map {
        $0.count == 0
      }
      .removeDuplicates()
      .sink { [weak self] empty in
        guard let self = self else { return }

        if empty {
          let emptyLabel = UILabel(frame: CGRect.zero)
          emptyLabel.translatesAutoresizingMaskIntoConstraints = false
          emptyLabel.text = "Tap + to add a new feed"
          emptyLabel.numberOfLines = 0
          emptyLabel.textColor = .lightGray
          self.emptyLabel = emptyLabel

          let tableView = self.tableView!
          tableView.addSubview(emptyLabel)
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: tableView,
            attribute: .centerX,
            multiplier: 1,
            constant: 0))
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .leading,
            relatedBy: .greaterThanOrEqual,
            toItem: tableView,
            attribute: .leading,
            multiplier: 1,
            constant: 8))
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .trailing,
            relatedBy: .lessThanOrEqual,
            toItem: tableView,
            attribute: .trailing,
            multiplier: 1,
            constant: 8))
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: tableView,
            attribute: .top,
            multiplier: 1,
            constant: 44.0 * 1.5))
        } else {
          if let emptyLabel = self.emptyLabel {
            emptyLabel.removeFromSuperview()
          }
        }
      }
      .store(in: &self.cancellables)
  }

  private func setupNavigation() {
    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    rightBarButtonItem.publisher()
      .map { [weak self] _ -> AnyPublisher<Bool, Never> in
        guard let self = self else { return Just<Bool>(false).eraseToAnyPublisher() }

        let viewController = AppSelectFeedViewController()
        viewController.viewModel = self.viewModel.feedListViewModel()
        self.navigationController?.pushViewController(viewController, animated: true)

        return viewController.finished
          .flatMap { [weak self] feedId -> AnyPublisher<Bool, Never> in
            guard let self = self else { return Just<Bool>(false).eraseToAnyPublisher() }
            guard let feedId = feedId else { return Just<Bool>(false).eraseToAnyPublisher() }
            return self.viewModel.addTodayWidgetFeed(forFeedId: feedId)
          }
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .sink { [weak self] _ in
        guard let self = self else { return }
        self.navigationController?.popViewController(animated: true)
      }
      .store(in: &self.cancellables)
    self.navigationItem.rightBarButtonItems = [self.editButtonItem, rightBarButtonItem]
  }
}
