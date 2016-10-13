//
//  MyElectricAppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import Charts

class MyElectricAppViewController: UIViewController {

  var viewModel: MyElectricAppViewModel!

  @IBOutlet private var mainView: UIView!
  @IBOutlet private var powerLabel: UILabel!
  @IBOutlet private var usageTodayLabel: UILabel!
  @IBOutlet fileprivate var lineChart: LineChartView!
  @IBOutlet fileprivate var barChart: BarChartView!

  @IBOutlet private var configureView: UIView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupCharts()
    self.setupBindings()
    self.setupNavigation()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active.value = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    self.viewModel.active.value = false
  }

  private func setupBindings() {
    self.viewModel.title
      .drive(self.rx.title)
      .addDisposableTo(self.disposeBag)

    self.viewModel.data
      .map { $0.powerNow }
      .map { $0.prettyFormat() + "W" }
      .drive(self.powerLabel.rx.text)
      .addDisposableTo(self.disposeBag)

    self.viewModel.data
      .map { $0.usageToday }
      .map { $0.prettyFormat() + "kWh" }
      .drive(self.usageTodayLabel.rx.text)
      .addDisposableTo(self.disposeBag)

    self.viewModel.data
      .map { $0.lineChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }

        guard let data = strongSelf.lineChart.data,
          let dataSet = data.getDataSetByIndex(0) else {
            return
        }

        dataSet.clear()

        for point in dataPoints {
          let x = point.time.timeIntervalSince1970
          let y = point.value

          let yDataEntry = ChartDataEntry(x: x, y: y)
          data.addEntry(yDataEntry, dataSetIndex: 0)
        }

        dataSet.notifyDataSetChanged()
        data.notifyDataChanged()
        strongSelf.lineChart.notifyDataSetChanged()
        })
      .addDisposableTo(self.disposeBag)

    self.viewModel.data
      .map { $0.barChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }

        guard let data = strongSelf.barChart.data,
          let dataSet = data.getDataSetByIndex(0) else {
            return
        }

        dataSet.clear()

        for point in dataPoints {
          // 'x' here means the offset in days from 'today'
          let x = floor(point.time.timeIntervalSinceNow / 86400)
          let y = point.value

          let yDataEntry = BarChartDataEntry(x: x, y: y)
          data.addEntry(yDataEntry, dataSetIndex: 0)
        }

        dataSet.notifyDataSetChanged()
        data.notifyDataChanged()
        strongSelf.barChart.notifyDataSetChanged()
        })
      .addDisposableTo(self.disposeBag)

    self.viewModel.isReady
      .map { !$0 }
      .drive(self.mainView.rx.hidden)
      .addDisposableTo(self.disposeBag)

    self.viewModel.isReady
      .drive(self.configureView.rx.hidden)
      .addDisposableTo(self.disposeBag)
  }

  private func setupNavigation() {
    let rightBarButtonItem = UIBarButtonItem(title: "Configure", style: .plain, target: nil, action: nil)
    rightBarButtonItem.rx.tap
      .subscribe(onNext: { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.showConfigure()
        })
      .addDisposableTo(self.disposeBag)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

  private func showConfigure() {
    let configViewController = AppConfigViewController()
    configViewController.viewModel = self.viewModel.configViewModel()
    configViewController.finished
      .drive(onCompleted: { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.dismiss(animated: true, completion: nil)
        })
      .addDisposableTo(self.disposeBag)
    let navController = UINavigationController(rootViewController: configViewController)
    self.present(navController, animated: true, completion: nil)
  }

}

extension MyElectricAppViewController {

  fileprivate func setupCharts() {
    self.setupLineChart()
    self.setupBarChart()
  }

  fileprivate func setupLineChart() {
    guard let lineChart = self.lineChart else {
      return
    }

    lineChart.drawGridBackgroundEnabled = false
    lineChart.legend.enabled = false
    lineChart.rightAxis.enabled = false
    lineChart.chartDescription = nil
    lineChart.noDataText = ""

    let xAxis = lineChart.xAxis
    xAxis.drawAxisLineEnabled = false
    xAxis.drawGridLinesEnabled = false
    xAxis.drawLabelsEnabled = true
    xAxis.labelPosition = .bottom
    xAxis.labelTextColor = .black
    xAxis.valueFormatter = ChartDateValueFormatter(.auto)
    xAxis.granularity = 3600

    let yAxis = lineChart.leftAxis
    yAxis.labelPosition = .insideChart
    yAxis.drawTopYLabelEntryEnabled = false
    yAxis.drawGridLinesEnabled = false
    yAxis.drawAxisLineEnabled = false
    yAxis.labelTextColor = .black

    let dataSet = LineChartDataSet(values: [ChartDataEntry(x: 0, y: 0)], label: nil)
    dataSet.setColor(EmonCMSColors.Chart.Blue)
    dataSet.fillColor = EmonCMSColors.Chart.Blue
    dataSet.valueTextColor = .black
    dataSet.drawFilledEnabled = true
    dataSet.drawCirclesEnabled = false
    dataSet.drawValuesEnabled = false
    dataSet.highlightEnabled = false

    let data = LineChartData()
    data.addDataSet(dataSet)
    lineChart.data = data
  }

  fileprivate func setupBarChart() {
    guard let barChart = self.barChart else {
      return
    }

    barChart.drawGridBackgroundEnabled = false
    barChart.legend.enabled = false
    barChart.leftAxis.enabled = false
    barChart.rightAxis.enabled = false
    barChart.chartDescription = nil
    barChart.noDataText = ""
    barChart.isUserInteractionEnabled = false
    barChart.extraBottomOffset = 2
    barChart.drawValueAboveBarEnabled = true

    let xAxis = barChart.xAxis
    xAxis.labelPosition = .bottomInside
    xAxis.labelTextColor = .white
    xAxis.valueFormatter = DayRelativeToTodayValueFormatter()
    xAxis.drawGridLinesEnabled = false
    xAxis.drawAxisLineEnabled = false
    xAxis.drawLabelsEnabled = true
    xAxis.granularity = 1
    xAxis.labelCount = 14

    let dataSet = BarChartDataSet(values: [BarChartDataEntry(x: 0, y: 0)], label: "kWh")
    dataSet.setColor(EmonCMSColors.Chart.Blue)
    dataSet.valueTextColor = .black

    let data = BarChartData()
    data.addDataSet(dataSet)
    barChart.data = data
  }

}
