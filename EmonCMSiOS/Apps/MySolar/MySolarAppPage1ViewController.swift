//
//  MySolarAppPage1ViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 29/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

import Charts

final class MySolarAppPage1ViewController: AppPageViewController {
  var typedViewModel: MySolarAppPage1ViewModel {
    return self.viewModel as! MySolarAppPage1ViewModel
  }

  @IBOutlet private var dateSegmentedControl: UISegmentedControl!
  @IBOutlet private var useLabelView: AppTitleAndValueView!
  @IBOutlet private var importLabelView: AppTitleAndValueView!
  @IBOutlet private var solarLabelView: AppTitleAndValueView!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var solarBoxView: AppBoxesFeedView!
  @IBOutlet private var gridBoxView: AppBoxesFeedView!
  @IBOutlet private var houseBoxView: AppBoxesFeedView!
  @IBOutlet private var solarToHouseArrowView: AppBoxesArrowView!
  @IBOutlet private var solarToGridArrowView: AppBoxesArrowView!
  @IBOutlet private var gridToHouseArrowView: AppBoxesArrowView!

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.useLabelView.alignment = .left
    self.useLabelView.valueColor = EmonCMSColors.Apps.Use
    self.importLabelView.alignment = .center
    self.importLabelView.valueColor = EmonCMSColors.Apps.Import
    self.solarLabelView.alignment = .right
    self.solarLabelView.valueColor = EmonCMSColors.Apps.Solar

    self.setupCharts()
    self.setupBoxView()
    self.setupBindings()
  }

  private func setupBindings() {
    self.dateSegmentedControl.publisher(for: \.selectedSegmentIndex)
      .map {
        DateRange.from1h8hDMYSegmentedControlIndex($0)
      }
      .assign(to: \.dateRange, on: self.viewModel)
      .store(in: &self.cancellables)

    func powerFormat(powerNow: Double?) -> String {
      let value: String
      if let powerNow = powerNow {
        value = powerNow.prettyFormat()
      } else {
        value = "- "
      }
      return value + "W"
    }

    self.typedViewModel.$data
      .map { $0?.useNow }
      .map(powerFormat)
      .assign(to: \.value, on: self.useLabelView)
      .store(in: &self.cancellables)

    let importExport = self.typedViewModel.$data
      .map { data -> (String, UIColor) in
        guard let value = data?.importNow else { return ("-", UIColor.black) }

        switch value.sign {
        case .plus:
          return ("IMPORT", EmonCMSColors.Apps.Import)
        case .minus:
          return ("EXPORT", EmonCMSColors.Apps.Export)
        }
      }

    importExport
      .map { $0.0 }
      .assign(to: \.title, on: self.importLabelView)
      .store(in: &self.cancellables)

    importExport
      .map { $0.1 }
      .assign(to: \.valueColor, on: self.importLabelView)
      .store(in: &self.cancellables)

    self.typedViewModel.$data
      .map {
        if let value = $0?.importNow {
          return abs(value)
        } else {
          return nil
        }
      }
      .map(powerFormat)
      .assign(to: \.value, on: self.importLabelView)
      .store(in: &self.cancellables)

    self.typedViewModel.$data
      .map { $0?.solarNow }
      .map(powerFormat)
      .assign(to: \.value, on: self.solarLabelView)
      .store(in: &self.cancellables)

    self.typedViewModel.$data
      .map { $0?.lineChartData }
      .sink { [weak self] dataPoints in
        guard let self = self else { return }
        self.updateLineChartData(dataPoints)
        self.updateBoxViewData(dataPoints)
      }
      .store(in: &self.cancellables)
  }
}

extension MySolarAppPage1ViewController {
  private func setupCharts() {
    ChartHelpers.setupAppLineChart(self.lineChart)
  }

  private func updateLineChartData(_ dataPoints: (use: [DataPoint<Double>], solar: [DataPoint<Double>])?) {
    if let dataPoints = dataPoints {
      let data = self.lineChart.lineData ?? LineChartData()
      self.lineChart.data = data

      ChartHelpers.updateLineChart(withData: data, forSet: 0, withPoints: dataPoints.use) {
        $0.setColor(EmonCMSColors.Chart.Blue)
        $0.fillColor = EmonCMSColors.Chart.Blue
      }
      ChartHelpers.updateLineChart(withData: data, forSet: 1, withPoints: dataPoints.solar) {
        $0.setColor(EmonCMSColors.Chart.Yellow)
        $0.fillColor = EmonCMSColors.Chart.Yellow
      }

      self.lineChart.leftAxis.axisMinimum = min(data.yMin, 0)
    } else {
      self.lineChart.data = nil
    }

    self.lineChart.notifyDataSetChanged()
  }
}

extension MySolarAppPage1ViewController {
  private func setupBoxView() {
    self.solarBoxView.backgroundColor = EmonCMSColors.Apps.Solar
    self.solarBoxView.name = "SOLAR"
    self.solarBoxView.unit = "kWh"

    self.gridBoxView.backgroundColor = EmonCMSColors.Apps.Grid
    self.gridBoxView.name = "GRID"
    self.gridBoxView.unit = "kWh"

    self.houseBoxView.backgroundColor = EmonCMSColors.Apps.House
    self.houseBoxView.name = "HOUSE"
    self.houseBoxView.unit = "kWh"

    self.solarToHouseArrowView.unit = "kWh"
    self.solarToHouseArrowView.direction = .down

    self.solarToGridArrowView.unit = "kWh"
    self.solarToGridArrowView.direction = .right

    self.gridToHouseArrowView.unit = "kWh"
    self.gridToHouseArrowView.direction = .down
  }

  private func updateBoxViewData(_ dataPoints: (use: [DataPoint<Double>], solar: [DataPoint<Double>])?) {
    guard let dataPoints = dataPoints else { return }

    let use = dataPoints.use
    let solar = dataPoints.solar
    guard use.count > 0, solar.count > 0 else { return }

    var totalUse = 0.0
    var totalSolar = 0.0
    var totalImport = 0.0
    var solarToGrid = 0.0
    var solarToHouse = 0.0
    var gridToHouse = 0.0

    DataPoint<Double>.merge(pointsFrom: [use, solar]) { timeDelta, _, values in
      let wattsToKWH = { (power: Double) -> Double in
        (power / 1000.0) * (timeDelta / 3600.0)
      }

      let useValue = wattsToKWH(values[0])
      let solarValue = wattsToKWH(values[1])
      let importValue = useValue - solarValue

      totalUse += useValue
      totalSolar += solarValue
      totalImport += importValue

      if importValue > 0 { // Importing
        gridToHouse += importValue
        solarToHouse += solarValue
      } else { // Exporting
        solarToGrid += -importValue
        solarToHouse += useValue
      }
    }

    self.solarBoxView.value = totalSolar
    self.gridBoxView.value = totalImport
    self.houseBoxView.value = totalUse
    self.solarToGridArrowView.value = solarToGrid
    self.solarToHouseArrowView.value = solarToHouse
    self.gridToHouseArrowView.value = gridToHouse
  }
}
