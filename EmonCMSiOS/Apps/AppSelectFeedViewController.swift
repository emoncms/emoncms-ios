//
//  AppSelectFeedViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

final class AppSelectFeedViewController: UITableViewController {

  var viewModel: FeedListViewModel!

  fileprivate let searchController = UISearchController(searchResultsController: nil)
  fileprivate let searchSubject = BehaviorSubject<String>(value: "")

  fileprivate let disposeBag = DisposeBag()

  lazy var finished: Driver<String?> = {
    return self.finishedSubject.asDriver(onErrorJustReturn: nil)
  }()
  private var finishedSubject = PublishSubject<String?>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Select Feed"
    self.tableView.accessibilityIdentifier = AccessibilityIdentifiers.Lists.AppSelectFeed

    self.tableView.estimatedRowHeight = 44.0
    self.tableView.rowHeight = UITableView.automaticDimension
    self.tableView.refreshControl = UIRefreshControl()

    self.searchController.searchResultsUpdater = self
    self.searchController.dimsBackgroundDuringPresentation = false
    self.tableView.tableHeaderView = searchController.searchBar

    self.setupDataSource()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active.accept(false)
  }

  private func setupDataSource() {
    let dataSource = RxTableViewSectionedReloadDataSource<FeedListViewModel.Section>(
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

    self.viewModel.feeds
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)
  }

  private func setupBindings() {
    let refreshControl = self.tableView.refreshControl!

    refreshControl.rx.controlEvent(.valueChanged)
      .bind(to: self.viewModel.refresh)
      .disposed(by: self.disposeBag)

    self.viewModel.isRefreshing
      .drive(refreshControl.rx.isRefreshing)
      .disposed(by: self.disposeBag)

    self.searchSubject
      .bind(to: self.viewModel.searchTerm)
      .disposed(by: self.disposeBag)

    self.tableView.rx
      .modelSelected(FeedListViewModel.ListItem.self)
      .do(onNext: { [weak self] _ in
        guard let self = self else { return }
        self.searchController.dismiss(animated: true, completion: nil)
      })
      .map { $0.feedId }
      .subscribe(self.finishedSubject)
      .disposed(by: self.disposeBag)
  }

}

extension AppSelectFeedViewController: UISearchResultsUpdating {

  public func updateSearchResults(for searchController: UISearchController) {
    searchSubject.onNext(searchController.searchBar.text ?? "")
  }

}
