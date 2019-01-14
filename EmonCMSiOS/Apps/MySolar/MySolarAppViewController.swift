//
//  MySolarAppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/12/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import Charts

final class MySolarAppViewController: UIViewController {

  var viewModel: MySolarAppViewModel!

  @IBOutlet private var mainView: UIView!
  @IBOutlet private var useLabel: UILabel!
  @IBOutlet private var importTitleLabel: UILabel!
  @IBOutlet private var importLabel: UILabel!
  @IBOutlet private var solarLabel: UILabel!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var solarBoxView: AppBoxesFeedView!
  @IBOutlet private var gridBoxView: AppBoxesFeedView!
  @IBOutlet private var houseBoxView: AppBoxesFeedView!
  @IBOutlet private var solarToHouseArrowView: AppBoxesArrowView!
  @IBOutlet private var solarToGridArrowView: AppBoxesArrowView!
  @IBOutlet private var gridToHouseArrowView: AppBoxesArrowView!
  @IBOutlet private var bannerView: UIView!
  @IBOutlet private var bannerLabel: UILabel!
  @IBOutlet private var bannerSpinner: UIActivityIndicatorView!

  @IBOutlet private var configureView: UIView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupCharts()
    self.setupBoxView()
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

    func powerFormat(powerNow: Double?) -> String {
      let value: String
      if let powerNow = powerNow {
        value = powerNow.prettyFormat()
      } else {
        value = "- "
      }
      return value + "W"
    }

    self.viewModel.data
      .map { $0?.useNow }
      .map(powerFormat)
      .drive(self.useLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map {
        guard let value = $0?.importNow else { return "-" }

        switch value.sign {
        case .plus:
          return "IMPORT"
        case .minus:
          return "EXPORT"
        }
      }
      .drive(self.importTitleLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map {
        if let value = $0?.importNow {
          return abs(value)
        } else {
          return nil
        }
      }
      .map(powerFormat)
      .drive(self.importLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map { $0?.solarNow }
      .map(powerFormat)
      .drive(self.solarLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map { $0?.lineChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateLineChartData(dataPoints)
        strongSelf.updateBoxViewData(dataPoints)
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

extension MySolarAppViewController {

  fileprivate func setupCharts() {
    self.setupLineChart()
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

  fileprivate func updateLineChartData(_ dataPoints: (use: [DataPoint], solar: [DataPoint])?) {
    if let dataPoints = dataPoints {
      let data = self.lineChart.data ?? LineChartData()

      var useEntries: [ChartDataEntry] = []
      for point in dataPoints.use {
        let x = point.time.timeIntervalSince1970
        let y = point.value

        let yDataEntry = ChartDataEntry(x: x, y: y)
        useEntries.append(yDataEntry)
      }

      if let dataSet = data.getDataSetByIndex(0)
      {
        dataSet.clear()
        for entry in useEntries {
          _ = dataSet.addEntry(entry)
        }

        dataSet.notifyDataSetChanged()
        data.notifyDataChanged()
      } else {
        let dataSet = LineChartDataSet(values: useEntries, label: nil)
        dataSet.setColor(EmonCMSColors.Chart.Blue)
        dataSet.fillColor = EmonCMSColors.Chart.Blue
        dataSet.valueTextColor = .black
        dataSet.drawFilledEnabled = true
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.highlightEnabled = false
        dataSet.fillFormatter = DefaultFillFormatter(block: { (_, _) in 0 })

        data.addDataSet(dataSet)

        self.lineChart.data = data
      }

      var solarEntries: [ChartDataEntry] = []
      for point in dataPoints.solar {
        let x = point.time.timeIntervalSince1970
        let y = point.value

        let yDataEntry = ChartDataEntry(x: x, y: y)
        solarEntries.append(yDataEntry)
      }

      if let dataSet = data.getDataSetByIndex(1)
      {
        dataSet.clear()
        for entry in solarEntries {
          _ = dataSet.addEntry(entry)
        }

        dataSet.notifyDataSetChanged()
        data.notifyDataChanged()
      } else {
        let dataSet = LineChartDataSet(values: solarEntries, label: nil)
        dataSet.setColor(EmonCMSColors.Chart.Yellow)
        dataSet.fillColor = EmonCMSColors.Chart.Yellow
        dataSet.valueTextColor = .black
        dataSet.drawFilledEnabled = true
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.highlightEnabled = false
        dataSet.fillFormatter = DefaultFillFormatter(block: { (_, _) in 0 })

        data.addDataSet(dataSet)

        self.lineChart.data = data
      }
    } else {
      self.lineChart.data = nil
    }

    self.lineChart.notifyDataSetChanged()
  }

}

extension MySolarAppViewController {

  private func setupBoxView() {
    self.solarBoxView.backgroundColor = EmonCMSColors.Apps.Solar
    self.solarBoxView.feedName = "SOLAR"
    self.solarBoxView.feedUnit = "kWh"

    self.gridBoxView.backgroundColor = EmonCMSColors.Apps.Grid
    self.gridBoxView.feedName = "GRID"
    self.gridBoxView.feedUnit = "kWh"

    self.houseBoxView.backgroundColor = EmonCMSColors.Apps.House
    self.houseBoxView.feedName = "HOUSE"
    self.houseBoxView.feedUnit = "kWh"

    self.solarToHouseArrowView.unit = "kWh"
    self.solarToHouseArrowView.direction = .down

    self.solarToGridArrowView.unit = "kWh"
    self.solarToGridArrowView.direction = .right

    self.gridToHouseArrowView.unit = "kWh"
    self.gridToHouseArrowView.direction = .down
  }

  private func updateBoxViewData(_ dataPoints: (use: [DataPoint], solar: [DataPoint])?) {
    guard let dataPoints = dataPoints else { return }

    let use = dataPoints.use
    let solar = dataPoints.solar
    guard use.count > 0, solar.count > 0 else { return }

    var lastTime: Date? = nil
    var useIndex = use.startIndex
    var solarIndex = solar.startIndex

    var totalUse = 0.0
    var totalSolar = 0.0
    var totalImport = 0.0
    var solarToGrid = 0.0
    var solarToHouse = 0.0
    var gridToHouse = 0.0

    while useIndex < use.endIndex && solarIndex < solar.endIndex {
      let usePoint = use[useIndex]
      let solarPoint = solar[solarIndex]

      let useTime = usePoint.time
      let solarTime = solarPoint.time

      guard useTime == solarTime else {
        if useTime < solarTime {
          useIndex = useIndex.advanced(by: 1)
        } else {
          solarIndex = solarIndex.advanced(by: 1)
        }
        lastTime = nil
        continue
      }

      guard let unwrappedLastTime = lastTime else {
        lastTime = useTime
        continue
      }

      let timeDelta = useTime.timeIntervalSince(unwrappedLastTime)
      lastTime = useTime

      let wattsToKWH = { (power: Double) -> Double in
        return (power / 1000.0) * (timeDelta / 3600.0)
      }

      let useValue = wattsToKWH(usePoint.value)
      let solarValue = wattsToKWH(solarPoint.value)
      let importValue = useValue - solarValue

      totalUse += useValue
      totalSolar += solarValue

      if importValue > 0 { // Importing
        totalImport += importValue
        gridToHouse += importValue
        solarToHouse += useValue
      } else { // Exporting
        solarToGrid += (-importValue)
        solarToHouse += solarValue
      }

      useIndex = useIndex.advanced(by: 1)
      solarIndex = solarIndex.advanced(by: 1)
    }

    self.solarBoxView.feedValue = totalSolar
    self.gridBoxView.feedValue = totalImport
    self.houseBoxView.feedValue = totalUse
    self.solarToGridArrowView.value = solarToGrid
    self.solarToHouseArrowView.value = solarToHouse
    self.gridToHouseArrowView.value = gridToHouse
  }

}
