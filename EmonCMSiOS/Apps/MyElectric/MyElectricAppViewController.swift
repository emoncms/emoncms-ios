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

final class MyElectricAppViewController: UIViewController {

  var viewModel: MyElectricAppViewModel!

  @IBOutlet private var mainView: UIView!
  @IBOutlet private var powerLabel: UILabel!
  @IBOutlet private var usageTodayLabel: UILabel!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var barChart: BarChartView!
  @IBOutlet private var bannerView: UIView!
  @IBOutlet private var bannerLabel: UILabel!
  @IBOutlet private var bannerSpinner: UIActivityIndicatorView!

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
    self.viewModel.active.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    self.viewModel.active.accept(false)
  }

  private func setupBindings() {
    self.viewModel.title
      .drive(self.rx.title)
      .disposed(by: self.disposeBag)

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
      .disposed(by: self.disposeBag)

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
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map { $0?.lineChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateLineChartData(dataPoints)
        })
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map { $0?.barChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateBarChartData(dataPoints)
        })
      .disposed(by: self.disposeBag)

    self.viewModel.isReady
      .map { !$0 }
      .drive(self.mainView.rx.isHidden)
      .disposed(by: self.disposeBag)

    self.viewModel.isReady
      .drive(self.configureView.rx.isHidden)
      .disposed(by: self.disposeBag)

    self.viewModel.errors
      .drive(onNext: { [weak self] error in
        guard let strongSelf = self else { return }

        switch error {
        case .initialFailed:
          let alert = UIAlertController(title: "Error", message: "Failed to connect to emoncms. Please try again.", preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
          strongSelf.present(alert, animated: true, completion: nil)
        default:
          break
        }
      })
      .disposed(by: self.disposeBag)

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    self.viewModel.bannerBarState
      .drive(onNext: { [weak self] state in
        guard let strongSelf = self else { return }

        switch state {
        case .loading:
          strongSelf.bannerSpinner.startAnimating()
          strongSelf.bannerLabel.text = "Loading"
          strongSelf.bannerView.backgroundColor = UIColor.lightGray
        case .error(let message):
          strongSelf.bannerSpinner.stopAnimating()
          strongSelf.bannerLabel.text = message
          strongSelf.bannerView.backgroundColor = EmonCMSColors.ErrorRed
        case .loaded(let updateTime):
          strongSelf.bannerSpinner.stopAnimating()
          strongSelf.bannerLabel.text = "Last updated: \(dateFormatter.string(from: updateTime))"
          strongSelf.bannerView.backgroundColor = UIColor.lightGray
        }
      })
      .disposed(by: self.disposeBag)
  }

  private func setupNavigation() {
    let rightBarButtonItem = UIBarButtonItem(title: "Configure", style: .plain, target: nil, action: nil)
    rightBarButtonItem.rx.tap
      .flatMap { [weak self] _ -> Driver<AppUUIDAndCategory?> in
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
      .disposed(by: self.disposeBag)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

}

extension MyElectricAppViewController {

  private func setupCharts() {
    self.setupLineChart()
    self.setupBarChart()
  }

  private func setupLineChart() {
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

  private func setupBarChart() {
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
    barChart.extraBottomOffset = 0
    barChart.drawValueAboveBarEnabled = true

    let xAxis = barChart.xAxis
    xAxis.labelPosition = .bottom
    xAxis.labelTextColor = .black
    xAxis.valueFormatter = DayRelativeToTodayValueFormatter()
    xAxis.drawGridLinesEnabled = false
    xAxis.drawAxisLineEnabled = false
    xAxis.drawLabelsEnabled = true
    xAxis.granularity = 1
    xAxis.labelCount = 14
  }

  private func updateLineChartData(_ dataPoints: [DataPoint]?) {
    if let dataPoints = dataPoints {
      let data = (self.lineChart.data as? LineChartData) ?? LineChartData()
      self.lineChart.data = data

      ChartHelpers.updateLineChart(withData: data, forSet: 0, withPoints: dataPoints) {
        $0.setColor(EmonCMSColors.Chart.Blue)
        $0.fillColor = EmonCMSColors.Chart.Blue
      }
    } else {
      self.lineChart.data = nil
    }

    self.lineChart.notifyDataSetChanged()
  }

  private func updateBarChartData(_ dataPoints: [DataPoint]?) {
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

    self.barChart.notifyDataSetChanged()
  }

}
