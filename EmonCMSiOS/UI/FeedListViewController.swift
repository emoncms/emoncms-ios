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

class FeedListViewController: UITableViewController {

  var viewModel: FeedListViewModel!

  private let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showFeed
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Feeds"
  }

  override func viewWillAppear(_ animated: Bool) {
    self.update()
  }

  func update() {
    self.tableView.refreshControl?.beginRefreshing()
    viewModel.update()
      .catchError() { _ in Observable.empty() }
      .observeOn(MainScheduler.instance)
      .subscribe(onCompleted: {
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
      })
      .addDisposableTo(self.disposeBag)
  }

  @IBAction private func refresh() {
    self.update()
  }

}

extension FeedListViewController {

  override func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.numberOfSections
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfFeeds(inSection: section)
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let feedViewModel = self.viewModel.feedViewModel(atIndexPath: indexPath)
    let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)
    cell.textLabel?.text = feedViewModel.name
    cell.detailTextLabel?.text = "\(feedViewModel.value)"
    return cell
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return self.viewModel.titleForSection(atIndex: section)
  }

}

extension FeedListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showFeed.rawValue {
      let feedViewController = segue.destination as! FeedViewController
      let selectedIndexPath = self.tableView.indexPathForSelectedRow!
      let feedViewModel = self.viewModel.feedViewModel(atIndexPath: selectedIndexPath)
      feedViewController.viewModel = feedViewModel
    }
  }

}
