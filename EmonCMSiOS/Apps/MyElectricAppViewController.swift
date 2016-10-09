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

class MyElectricAppViewController: UIViewController, AppViewController {

  var viewModel: MyElectricAppViewModel!

  var genericViewModel: AppViewModel! {
    get {
      return self.viewModel
    }
    set(vm) {
      self.viewModel = vm as! MyElectricAppViewModel
    }
  }

  @IBOutlet private var powerLabel: UILabel!
  @IBOutlet private var usageTodayLabel: UILabel!
  @IBOutlet fileprivate var lineChart: LineChartView!
  @IBOutlet fileprivate var barChart: BarChartView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "My Electric"

    self.setupCharts()
    self.setupBindings()
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
          // We minus 1 day here, because we want the date to represent the previous day.
          // For example:
          //   [0].time is Thursday midnight, [1].time is Friday midnight.
          //   [1].value - [0].value means kWh consumed on Thursday.
          let x = point.time.timeIntervalSince1970 - 86400
          let y = point.value

          let yDataEntry = BarChartDataEntry(x: x, y: y)
          data.addEntry(yDataEntry, dataSetIndex: 0)
        }

        dataSet.notifyDataSetChanged()
        data.notifyDataChanged()
        strongSelf.barChart.notifyDataSetChanged()
        })
      .addDisposableTo(self.disposeBag)
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
    xAxis.labelTextColor = .white
    xAxis.valueFormatter = ChartDateValueFormatter(.auto)

    let yAxis = lineChart.leftAxis
    yAxis.labelPosition = .insideChart
    yAxis.drawTopYLabelEntryEnabled = false
    yAxis.drawGridLinesEnabled = false
    yAxis.drawAxisLineEnabled = false
    yAxis.labelTextColor = .white

    let dataSet = LineChartDataSet(values: [ChartDataEntry(x: 0, y: 0)], label: nil)
    dataSet.setColor(EmonCMSColors.Chart.Blue)
    dataSet.fillColor = EmonCMSColors.Chart.Blue
    dataSet.valueTextColor = .white
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
    xAxis.valueFormatter = ChartDateValueFormatter(.format("eeeee"))
    xAxis.drawGridLinesEnabled = false
    xAxis.drawAxisLineEnabled = false
    xAxis.drawLabelsEnabled = true

    let dataSet = BarChartDataSet(values: [BarChartDataEntry(x: 0, y: 0)], label: "kWh")
    dataSet.setColor(EmonCMSColors.Chart.Blue)
    dataSet.valueTextColor = .white

    let data = BarChartData()
    data.addDataSet(dataSet)
    barChart.data = data
  }

}
