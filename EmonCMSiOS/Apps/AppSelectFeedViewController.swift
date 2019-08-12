//
//  AppSelectFeedViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit
import Combine

final class AppSelectFeedViewController: UITableViewController {

  var viewModel: FeedListViewModel!

  private let searchController = UISearchController(searchResultsController: nil)
  private let searchSubject = CurrentValueSubject<String, Never>("")

  private var dataSource: CombineTableViewDataSource<FeedListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()

  lazy var finished: AnyPublisher<String?, Never> = {
    return self.finishedSubject.eraseToAnyPublisher()
  }()
  private var finishedSubject = PassthroughSubject<String?, Never>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Select Feed"
    self.tableView.accessibilityIdentifier = AccessibilityIdentifiers.Lists.AppSelectFeed

    self.tableView.estimatedRowHeight = 44.0
    self.tableView.rowHeight = UITableView.automaticDimension
    self.tableView.refreshControl = UIRefreshControl()

    self.searchController.searchResultsUpdater = self
    self.searchController.obscuresBackgroundDuringPresentation = false
    self.tableView.tableHeaderView = searchController.searchBar

    self.setupDataSource()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active = false
  }

  private func setupDataSource() {
    let dataSource = CombineTableViewDataSource<FeedListViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ??
          UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = item.name
        cell.accessoryType = .disclosureIndicator

        return cell
    },
      titleForHeaderInSection: { (ds, index) in
        return ds.sectionModels[index].model
    })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$feeds
      .eraseToAnyPublisher()

    dataSource.assign(toTableView: self.tableView, items: items)
    self.dataSource = dataSource
  }

  private func setupBindings() {
    let refreshControl = self.tableView.refreshControl!

    refreshControl.publisher(for: .valueChanged)
      .becomeVoid()
      .subscribe(self.viewModel.refresh)
      .store(in: &self.cancellables)

    self.viewModel.isRefreshing
      .sink { refreshing in
        if refreshing {
          refreshControl.beginRefreshing()
        } else {
          refreshControl.endRefreshing()
        }
      }
      .store(in: &self.cancellables)

    self.searchSubject
      .assign(to: \.searchTerm, on: self.viewModel)
      .store(in: &self.cancellables)

    self.dataSource
      .modelSelected
      .handleEvents(receiveOutput: { [weak self] _ in
        guard let self = self else { return }
        self.searchController.dismiss(animated: true, completion: nil)
      })
      .map { $0.feedId }
      .subscribe(self.finishedSubject)
      .store(in: &self.cancellables)
  }

}

extension AppSelectFeedViewController: UISearchResultsUpdating {

  public func updateSearchResults(for searchController: UISearchController) {
    searchSubject.send(searchController.searchBar.text ?? "")
  }

}
