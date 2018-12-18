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
import Charts

final class FeedListViewController: UIViewController {

  var viewModel: FeedListViewModel!

  @IBOutlet fileprivate var tableView: UITableView!
  @IBOutlet fileprivate var refreshButton: UIBarButtonItem!
  @IBOutlet fileprivate var lineChartView: LineChartView!

  fileprivate let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showFeed
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Feeds"

    self.tableView.estimatedRowHeight = 68.0
    self.tableView.rowHeight = UITableView.automaticDimension

    if #available(iOS 10.0, *) {
      self.tableView.refreshControl = UIRefreshControl()
    }

    self.setupDataSource()
    self.setupChartView()
    self.setupBindings()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let topOfChartInTableView = self.lineChartView.convert(CGPoint.zero, to: self.tableView)
    let insetBottom = self.tableView.bounds.height - topOfChartInTableView.y

    var contentInset = self.tableView.contentInset
    contentInset.bottom = insetBottom
    self.tableView.contentInset = contentInset

    var scrollIndicatorInsets = self.tableView.scrollIndicatorInsets
    scrollIndicatorInsets.bottom = insetBottom
    self.tableView.scrollIndicatorInsets = scrollIndicatorInsets
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
    self.tableView.register(UINib(nibName: "ValueCell", bundle: nil), forCellReuseIdentifier: "ValueCell")

    let dataSource = RxTableViewSectionedReloadDataSource<FeedListViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "ValueCell", for: indexPath) as! ValueCell
        cell.titleLabel.text = item.name
        cell.valueLabel.text = item.value
        cell.accessoryType = .detailDisclosureButton

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
    },
      titleForHeaderInSection: { (ds, index) in
        return ds.sectionModels[index].model
    })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.feeds
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)

    let i = self.tableView.rx.itemSelected
    i
      .map { [weak self] indexPath -> FeedChartViewModel? in
        guard let strongSelf = self else { return nil }

        let item = try! dataSource.model(at: indexPath) as! FeedListViewModel.ListItem
        let chartViewModel = strongSelf.viewModel.feedChartViewModel(forItem: item)
        return chartViewModel
      }
      .flatMapLatest { [weak self] chartViewModel -> Observable<()> in
        let disposeBag = CompositeDisposable()

        if let chartViewModel = chartViewModel {
          chartViewModel.dateRange.accept(.relative(.hour8))
          let disposable = chartViewModel.dataPoints
            .drive(onNext: { [weak self] dataPoints in
              guard let strongSelf = self else { return }

              let chartView = strongSelf.lineChartView!

              guard !dataPoints.isEmpty else {
                chartView.data = nil
                chartView.notifyDataSetChanged()
                return
              }

              let dataSet = LineChartDataSet(values: [], label: nil)
              dataSet.valueTextColor = .lightGray
              dataSet.fillColor = .black
              dataSet.setColor(.black)
              dataSet.drawCirclesEnabled = false
              dataSet.drawFilledEnabled = true
              dataSet.drawValuesEnabled = false
              dataSet.fillFormatter = DefaultFillFormatter(block: { (_, _) in 0 })

              for point in dataPoints {
                let x = point.time.timeIntervalSince1970
                let y = point.value

                let yDataEntry = ChartDataEntry(x: x, y: y)
                _ = dataSet.addEntry(yDataEntry)
              }

              let data = LineChartData()
              data.addDataSet(dataSet)
              chartView.data = data
              
              chartView.notifyDataSetChanged()
            })
          chartViewModel.active.accept(true)
          _ = disposeBag.insert(disposable)
        }

        return Observable<()>.never()
          .do(onDispose: { 
            disposeBag.dispose()
          })
      }
      .subscribe()
      .disposed(by: self.disposeBag)

    self.tableView.rx.itemAccessoryButtonTapped
      .subscribe(onNext: { [weak self] indexPath in
        guard let strongSelf = self else { return }
        let item = try! dataSource.model(at: indexPath)
        strongSelf.performSegue(withIdentifier: Segues.showFeed.rawValue, sender: item)
      })
      .disposed(by: self.disposeBag)
  }

  private func setupChartView() {
    let chartView = self.lineChartView!

    chartView.noDataText = "Select a feed"
    chartView.dragEnabled = false
    chartView.pinchZoomEnabled = false
    chartView.highlightPerTapEnabled = false
    chartView.setScaleEnabled(false)
    chartView.chartDescription = nil
    chartView.drawGridBackgroundEnabled = false
    chartView.legend.enabled = false
    chartView.rightAxis.enabled = false

    let xAxis = chartView.xAxis
    xAxis.drawGridLinesEnabled = false
    xAxis.drawLabelsEnabled = false

    let yAxis = chartView.leftAxis
    yAxis.drawGridLinesEnabled = false
    yAxis.labelPosition = .outsideChart
    yAxis.drawZeroLineEnabled = true
  }

  private func setupBindings() {
    if #available(iOS 10.0, *) {
      let refreshControl = self.tableView.refreshControl!

      Observable.of(self.refreshButton.rx.tap, refreshControl.rx.controlEvent(.valueChanged))
        .merge()
        .bind(to: self.viewModel.refresh)
        .disposed(by: self.disposeBag)

      self.viewModel.isRefreshing
        .drive(refreshControl.rx.isRefreshing)
        .disposed(by: self.disposeBag)

      self.viewModel.isRefreshing
        .map { !$0 }
        .drive(self.refreshButton.rx.isEnabled)
        .disposed(by: self.disposeBag)
    }
  }

}

extension FeedListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showFeed.rawValue {
      let feedViewController = segue.destination as! FeedChartViewController
      let item = sender as! FeedListViewModel.ListItem
      let viewModel = self.viewModel.feedChartViewModel(forItem: item)
      feedViewController.viewModel = viewModel
    }
  }

}
