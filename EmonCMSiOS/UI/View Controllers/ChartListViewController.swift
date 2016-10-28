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
import RxDataSources

final class ChartListViewController: UITableViewController {

  var viewModel: ChartListViewModel!

  fileprivate let dataSource = RxTableViewSectionedReloadDataSource<ChartListViewModel.Section>()
  fileprivate let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showChart
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Charts"

    self.navigationItem.rightBarButtonItem = self.editButtonItem

    self.setupDataSource()
    self.setupBindings()
  }

  private func setupDataSource() {
    self.dataSource.configureCell = { (ds, tableView, indexPath, item) in
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
      cell.textLabel?.text = item.name
      return cell
    }

    self.dataSource.titleForHeaderInSection = { _ in "" }

    self.dataSource.canEditRowAtIndexPath = { _ in true }

    self.dataSource.canMoveRowAtIndexPath = { _ in false }

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.charts
      .map { [ChartListViewModel.Section(model: "", items: $0)] }
      .drive(self.tableView.rx.items(dataSource: self.dataSource))
      .addDisposableTo(self.disposeBag)
  }

  private func setupBindings() {
    self.tableView.rx
      .itemDeleted
      .map { [unowned self] in
        let item: ChartListViewModel.ListItem = try! self.tableView.rx.model($0)
        return item.chartId
      }
      .flatMap { [unowned self] in
        self.viewModel.deleteChart(withId: $0)
          .catchErrorJustReturn(())
      }
      .subscribe()
      .addDisposableTo(self.disposeBag)
  }

}

extension ChartListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showChart.rawValue {
      let feedViewController = segue.destination as! FeedChartViewController
      let selectedIndexPath = self.tableView.indexPathForSelectedRow!
      let item: ChartListViewModel.ListItem = try! self.tableView.rx.model(selectedIndexPath)
      let viewModel = self.viewModel.feedChartViewModel(forItem: item)
      feedViewController.viewModel = viewModel
    }
  }

}
