//
//  ViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 11/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

class FeedListViewController: UITableViewController {

  var viewModel: FeedListViewModel!

  fileprivate let dataSource = RxTableViewSectionedReloadDataSource<FeedListViewModel.Section>()
  fileprivate let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showFeed
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Feeds"

    self.setupDataSource()
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

  private func setupDataSource() {
    self.dataSource.configureCell = { (ds, tableView, indexPath, item) in
      let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)
      cell.textLabel?.text = item.name
      cell.detailTextLabel?.text = item.value
      return cell
    }

    self.dataSource.titleForHeaderInSection = { (ds, index) in
      return ds.sectionModels[index].header
    }

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.feeds
      .drive(self.tableView.rx.items(dataSource: self.dataSource))
      .addDisposableTo(self.disposeBag)
  }

  private func setupBindings() {
    let refreshControl = self.tableView.refreshControl!

    refreshControl.rx.controlEvent(.valueChanged)
      .bindTo(self.viewModel.refresh)
      .addDisposableTo(self.disposeBag)

    self.viewModel.isRefreshing
      .drive(refreshControl.rx.refreshing)
      .addDisposableTo(self.disposeBag)
  }

}

extension FeedListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showFeed.rawValue {
      let feedViewController = segue.destination as! FeedViewController
      let selectedIndexPath = self.tableView.indexPathForSelectedRow!
      let item = self.dataSource[selectedIndexPath]
      let viewModel = self.viewModel.feedChartViewModel(forItem: item)
      feedViewController.viewModel = viewModel
    }
  }

}
