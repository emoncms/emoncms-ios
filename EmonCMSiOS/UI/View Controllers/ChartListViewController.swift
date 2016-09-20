//
//  ChartListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 20/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class ChartListViewController: UITableViewController {

  var viewModel: ChartListViewModel!

  fileprivate let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showChart
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Charts"

    self.setupDataSource()
  }

  private func setupDataSource() {
    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.charts
      .drive(self.tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, element, cell) in
        cell.textLabel?.text = element.name
      }
      .addDisposableTo(self.disposeBag)
  }

}

extension ChartListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showChart.rawValue {
      let feedViewController = segue.destination as! FeedChartViewController
      let selectedIndexPath = self.tableView.indexPathForSelectedRow!
      let item: ChartListViewModel.ChartListItem = try! self.tableView.rx.model(selectedIndexPath)
      let viewModel = self.viewModel.feedChartViewModel(forItem: item)
      feedViewController.viewModel = viewModel
    }
  }

}
