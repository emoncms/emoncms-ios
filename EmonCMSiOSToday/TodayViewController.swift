//
//  TodayViewController.swift
//  EmonCMSiOSToday
//
//  Created by Matt Galloway on 26/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import NotificationCenter
import UIKit

import Charts
import Realm
import RealmSwift

class TodayViewController: UIViewController, NCWidgetProviding {
  @IBOutlet private var tableView: UITableView!
  @IBOutlet private var emptyLabel: UILabel!

  private var viewModel: TodayViewModel!

  private var dataSource: CombineTableViewDataSource<TodayViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    LogController.shared.initialise()

    self.tableView.allowsSelection = false
    self.tableView.estimatedRowHeight = 58.0
    self.tableView.rowHeight = UITableView.automaticDimension

    self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded

    let dataDirectory = DataController.sharedDataDirectory
    let realmController = RealmController(dataDirectory: dataDirectory)

    let requestProvider = NSURLSessionHTTPRequestProvider()
    let api = EmonCMSAPI(requestProvider: requestProvider)

    self.viewModel = TodayViewModel(realmController: realmController, api: api)

    self.setupDataSource()
    self.setupBindings()
  }

  private func setupDataSource() {
    self.tableView.register(UINib(nibName: "TodayViewFeedCell", bundle: nil), forCellReuseIdentifier: "Cell")

    let dataSource = CombineTableViewDataSource<TodayViewModel.Section>(
      configureCell: { _, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TodayViewFeedCell
        cell.feedNameLabel.text = item.feedName
        cell.accountNameLabel.text = item.accountName
        cell.feedValueLabel.text = item.feedChartData.last?.value.prettyFormat() ?? "---"
        cell.updateChart(withData: item.feedChartData)
        return cell
      },
      titleForHeaderInSection: { _, _ in "" },
      canEditRowAtIndexPath: { _, _ in true },
      canMoveRowAtIndexPath: { _, _ in false },
      heightForRowAtIndexPath: { _, _ in
        let CellMinimumHeight: CGFloat = 50

        guard let size = self.extensionContext?.widgetMaximumSize(for: .compact) else { return CellMinimumHeight }

        let countToShowInCompact = floor(size.height / CellMinimumHeight)
        let height = size.height / countToShowInCompact
        return height
      })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$feeds
      .map { [TodayViewModel.Section(model: "", items: $0)] }
      .eraseToAnyPublisher()

    dataSource.assign(toTableView: self.tableView, items: items)
    self.dataSource = dataSource

    self.viewModel.$feeds
      .map { $0.count == 0 }
      .assign(to: \.isHidden, on: self.tableView)
      .store(in: &self.cancellables)

    self.viewModel.$feeds
      .map { $0.count != 0 }
      .assign(to: \.isHidden, on: self.emptyLabel)
      .store(in: &self.cancellables)

    self.viewModel.$loadingState
      .map { loadingState in
        switch loadingState {
        case .loading:
          return "Loading\u{2026}"
        case .loaded:
          return "Select some feeds in Emoncms app"
        case .failed(let error):
          switch error {
          case .keychainLocked:
            return "Device locked"
          default:
            return "Failed to fetch feed data"
          }
        }
      }
      .assign(to: \.text, on: self.emptyLabel)
      .store(in: &self.cancellables)
  }

  private func setupBindings() {}
}

extension TodayViewController {
  func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
    self.viewModel.updateData()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .failure:
            completionHandler(.failed)
          default:
            break
          }
        },
        receiveValue: { updated in
          completionHandler(updated ? .newData : .noData)
        })
      .store(in: &self.cancellables)
  }

  func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
    UIView.animate(withDuration: 0.3) {
      switch activeDisplayMode {
      case .compact:
        self.preferredContentSize = maxSize
      default:
        self.preferredContentSize = self.tableView.contentSize
      }
    }
  }
}
