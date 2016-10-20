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
      .map { $0?.powerNow }
      .map {
        let value: String
        if let powerNow = $0 {
          value = powerNow.prettyFormat()
        } else {
          value = "- "
        }
        return value + "W"
      }
      .drive(self.powerLabel.rx.text)
      .addDisposableTo(self.disposeBag)

    self.viewModel.data
      .map { $0?.usageToday }
      .map {
        let value: String
        if let usageToday = $0 {
          value = usageToday.prettyFormat()
        } else {
          value = "- "
        }
        return value + "kWh"
      }
      .drive(self.usageTodayLabel.rx.text)
      .addDisposableTo(self.disposeBag)

    self.viewModel.data
      .map { $0?.lineChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateLineChartData(dataPoints)
        })
      .addDisposableTo(self.disposeBag)

    self.viewModel.data
      .map { $0?.barChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateBarChartData(dataPoints)
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
      .flatMap { [weak self] _ -> Driver<String?> in
        guard let strongSelf = self else { return Driver.empty() }

        let configViewController = AppConfigViewController()
        configViewController.viewModel = strongSelf.viewModel.configViewModel()
        let navController = UINavigationController(rootViewController: configViewController)
        strongSelf.present(navController, animated: true, completion: nil)

        return configViewController.finished
      }
      .subscribe(onNext: { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.dismiss(animated: true, completion: nil)
        })
      .addDisposableTo(self.disposeBag)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
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
    lineChart.noDataText = "Loading data..."
    lineChart.noDataTextColor = .black
    lineChart.isUserInteractionEnabled = false

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
    yAxis.drawZeroLineEnabled = true
    yAxis.drawGridLinesEnabled = false
    yAxis.drawAxisLineEnabled = false
    yAxis.labelTextColor = .black
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
    barChart.noDataText = "Loading data..."
    barChart.noDataTextColor = .black
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
  }

  fileprivate func updateLineChartData(_ dataPoints: [DataPoint]?) {
    if let dataPoints = dataPoints {
      var entries: [ChartDataEntry] = []
      for point in dataPoints {
        let x = point.time.timeIntervalSince1970
        let y = point.value

        let yDataEntry = ChartDataEntry(x: x, y: y)
        entries.append(yDataEntry)
      }

      if let data = self.lineChart.data,
        let dataSet = data.getDataSetByIndex(0)
      {
        dataSet.clear()
        for entry in entries {
          _ = dataSet.addEntry(entry)
        }

        dataSet.notifyDataSetChanged()
        data.notifyDataChanged()
        self.lineChart.notifyDataSetChanged()
      } else {
        let dataSet = LineChartDataSet(values: entries, label: nil)
        dataSet.setColor(EmonCMSColors.Chart.Blue)
        dataSet.fillColor = EmonCMSColors.Chart.Blue
        dataSet.valueTextColor = .black
        dataSet.drawFilledEnabled = true
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.highlightEnabled = false
        dataSet.fillFormatter = DefaultFillFormatter(block: { (_, _) in 0 })

        let data = LineChartData()
        data.addDataSet(dataSet)

        self.lineChart.data = data
      }
    } else {
      self.lineChart.data = nil
    }
  }

  fileprivate func updateBarChartData(_ dataPoints: [DataPoint]?) {
    if let dataPoints = dataPoints {
      var entries: [ChartDataEntry] = []
      for point in dataPoints {
        // 'x' here means the offset in days from 'today'
        let x = floor(point.time.timeIntervalSinceNow / 86400)
        let y = point.value

        let yDataEntry = BarChartDataEntry(x: x, y: y)
        entries.append(yDataEntry)
      }

      if let data = self.barChart.data,
        let dataSet = data.getDataSetByIndex(0)
      {
        dataSet.clear()
        for entry in entries {
          _ = dataSet.addEntry(entry)
        }

        dataSet.notifyDataSetChanged()
        data.notifyDataChanged()
        self.barChart.notifyDataSetChanged()
      } else {
        let dataSet = BarChartDataSet(values: entries, label: "kWh")
        dataSet.setColor(EmonCMSColors.Chart.Blue)
        dataSet.valueTextColor = .black

        let data = BarChartData()
        data.addDataSet(dataSet)

        self.barChart.data = data
      }
    } else {
      self.barChart.data = nil
    }
  }

}
