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

final class FeedListViewController: UITableViewController {

  var viewModel: FeedListViewModel!

  fileprivate let dataSource = RxTableViewSectionedReloadDataSource<FeedListViewModel.Section>()
  fileprivate let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showFeed
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Feeds"

    self.tableView.estimatedRowHeight = 68.0
    self.tableView.rowHeight = UITableViewAutomaticDimension

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
      let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedListCell
      cell.titleLabel.text = item.name
      cell.valueLabel.text = item.value

      let secondsAgo = Int(floor(max(-item.time.timeIntervalSinceNow, 0)))
      let value: String
      let colour: UIColor
      if secondsAgo < 60 {
        value = "\(secondsAgo) secs"
        colour = EmonCMSColors.ActivityIndicator.Green
      } else if secondsAgo < 3600 {
        value = "\(secondsAgo / 60) mins"
        colour = EmonCMSColors.ActivityIndicator.Yellow
      } else if secondsAgo < 86400 {
        value = "\(secondsAgo / 3600) hours"
        colour = EmonCMSColors.ActivityIndicator.Orange
      } else {
        value = "\(secondsAgo / 86400) days"
        colour = EmonCMSColors.ActivityIndicator.Red
      }
      cell.timeLabel.text = value
      cell.activityCircle.backgroundColor = colour

      return cell
    }

    self.dataSource.titleForHeaderInSection = { (ds, index) in
      return ds.sectionModels[index].model
    }

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.feeds
      .drive(self.tableView.rx.items(dataSource: self.dataSource))
      .addDisposableTo(self.disposeBag)
  }

  private func setupBindings() {
    let refreshControl = self.refreshControl!

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
      let feedViewController = segue.destination as! FeedChartViewController
      let selectedIndexPath = self.tableView.indexPathForSelectedRow!
      let item = self.dataSource[selectedIndexPath]
      let viewModel = self.viewModel.feedChartViewModel(forItem: item)
      feedViewController.viewModel = viewModel
    }
  }

}

final class FeedListCell: UITableViewCell {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var valueLabel: UILabel!
  @IBOutlet var timeLabel: UILabel!
  @IBOutlet var activityCircle: UIView!

  override func layoutSubviews() {
    super.layoutSubviews()
    self.activityCircle.layer.cornerRadius = self.activityCircle.bounds.width / 2
  }

}
