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

  fileprivate let dataSource = RxTableViewSectionedReloadDataSource<FeedListSection>()
  fileprivate let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showFeed
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Feeds"

    self.setupDataSource()
  }

  private func setupDataSource() {
    self.dataSource.configureCell = { (ds, tableView, indexPath, item) in
      let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)
      cell.textLabel?.text = item.name
      cell.detailTextLabel?.text = "\(item.value)"
      return cell
    }

    self.dataSource.titleForHeaderInSection = { (ds, index) in
      return ds.sectionModels[index].header
    }

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let refreshControl = self.tableView.refreshControl!

    let initial = Observable.just(())
    let refresh = refreshControl.rx.controlEvent(.valueChanged).map { _ in () }

    let driver = Observable.of(initial, refresh)
      .merge()
      .flatMapLatest { [weak self] _ -> Observable<[FeedListSection]> in
        guard let strongSelf = self else { return Observable.empty() }
        return strongSelf.viewModel.fetch()
      }
      .asDriver(onErrorJustReturn: [])

    driver
      .drive(self.tableView.rx.items(dataSource: self.dataSource))
      .addDisposableTo(self.disposeBag)

    driver
      .map { _ in false }
      .drive(refreshControl.rx.refreshing)
      .addDisposableTo(self.disposeBag)
  }

  override func viewWillAppear(_ animated: Bool) {
    self.update()
  }

  func update() {
    self.tableView.refreshControl?.beginRefreshing()
//    viewModel.update()
//      .catchError() { _ in Observable.empty() }
//      .observeOn(MainScheduler.instance)
//      .subscribe(onCompleted: {
//        self.tableView.reloadData()
//        self.tableView.refreshControl?.endRefreshing()
//      })
//      .addDisposableTo(self.disposeBag)
  }

}

extension FeedListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showFeed.rawValue {
      let feedViewController = segue.destination as! FeedViewController
      let selectedIndexPath = self.tableView.indexPathForSelectedRow!
      let feedViewModel = self.dataSource[selectedIndexPath]
      feedViewController.viewModel = feedViewModel
    }
  }

}
