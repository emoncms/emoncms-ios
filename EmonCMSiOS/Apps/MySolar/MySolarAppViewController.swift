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

final class MySolarAppViewController: AppViewController {

  var typedViewModel: MySolarAppViewModel {
    return self.viewModel as! MySolarAppViewModel
  }

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

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupCharts()
    self.setupBoxView()
    self.setupBindings()
  }

  private func setupBindings() {
    func powerFormat(powerNow: Double?) -> String {
      let value: String
      if let powerNow = powerNow {
        value = powerNow.prettyFormat()
      } else {
        value = "- "
      }
      return value + "W"
    }

    self.typedViewModel.data
      .map { $0?.useNow }
      .map(powerFormat)
      .drive(self.useLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
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

    self.typedViewModel.data
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

    self.typedViewModel.data
      .map { $0?.solarNow }
      .map(powerFormat)
      .drive(self.solarLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
      .map { $0?.lineChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateLineChartData(dataPoints)
        strongSelf.updateBoxViewData(dataPoints)
        })
      .disposed(by: self.disposeBag)
  }

}

extension MySolarAppViewController {

  private func setupCharts() {
    self.setupLineChart()
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

  private func updateLineChartData(_ dataPoints: (use: [DataPoint], solar: [DataPoint])?) {
    if let dataPoints = dataPoints {
      let data = (self.lineChart.data as? LineChartData) ?? LineChartData()
      self.lineChart.data = data

      ChartHelpers.updateLineChart(withData: data, forSet: 0, withPoints: dataPoints.use) {
        $0.setColor(EmonCMSColors.Chart.Blue)
        $0.fillColor = EmonCMSColors.Chart.Blue
      }
      ChartHelpers.updateLineChart(withData: data, forSet: 1, withPoints: dataPoints.solar) {
        $0.setColor(EmonCMSColors.Chart.Yellow)
        $0.fillColor = EmonCMSColors.Chart.Yellow
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

      defer {
        useIndex = useIndex.advanced(by: 1)
        solarIndex = solarIndex.advanced(by: 1)
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
    }

    self.solarBoxView.feedValue = totalSolar
    self.gridBoxView.feedValue = totalImport
    self.houseBoxView.feedValue = totalUse
    self.solarToGridArrowView.value = solarToGrid
    self.solarToHouseArrowView.value = solarToHouse
    self.gridToHouseArrowView.value = gridToHouse
  }

}
