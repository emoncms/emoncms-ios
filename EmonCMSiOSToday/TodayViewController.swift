//
//  TodayViewController.swift
//  EmonCMSiOSToday
//
//  Created by Matt Galloway on 26/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit
import NotificationCenter

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import Charts

class TodayViewController: UIViewController, NCWidgetProviding {

  @IBOutlet var tableView: UITableView!

  private var viewModel: TodayViewModel!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    LogController.shared.initialise()

    self.tableView.allowsSelection = false
    self.tableView.estimatedRowHeight = 58.0
    self.tableView.rowHeight = UITableView.automaticDimension

    self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded

    let dataDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.SharedApplicationGroupIdentifier)!
    let realmController = RealmController(dataDirectory: dataDirectory)

    let requestProvider = NSURLSessionHTTPRequestProvider()
    let api = EmonCMSAPI(requestProvider: requestProvider)

    self.viewModel = TodayViewModel(realmController: realmController, api: api)

    self.setupDataSource()
    self.setupBindings()
  }

  private func setupDataSource() {
    self.tableView.register(UINib(nibName: "TodayViewFeedCell", bundle: nil), forCellReuseIdentifier: "Cell")

    let dataSource = RxTableViewSectionedReloadDataSource<TodayViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TodayViewFeedCell
        cell.feedNameLabel.text = item.feedName
        cell.accountNameLabel.text = item.accountName
        cell.feedValueLabel.text = item.feedChartData.last?.value.prettyFormat() ?? "---"
        cell.updateChart(withData: item.feedChartData)
        return cell
    },
      titleForHeaderInSection: { _,_  in "" },
      canEditRowAtIndexPath: { _,_  in true },
      canMoveRowAtIndexPath: { _,_  in false })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.feeds
      .map { [TodayViewModel.Section(model: "", items: $0)] }
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)
  }

  private func setupBindings() {
  }

}

extension TodayViewController {

  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    self.viewModel.updateData()
      .subscribe(
        onNext: { updated in
          completionHandler(updated ? .newData : .noData)
        },
        onError: { _ in
          completionHandler(.failed)
        })
      .disposed(by: self.disposeBag)
  }

  func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
    switch activeDisplayMode {
    case .compact:
      self.preferredContentSize = maxSize;
    default:
      self.preferredContentSize = CGSize(width: self.tableView.contentSize.width, height: self.tableView.contentSize.height + 20);
    }
  }

}
