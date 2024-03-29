//
//  MySolarDivertAppPage1ViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

import Charts

final class MySolarDivertAppPage1ViewController: AppPageViewController {
  var typedViewModel: MySolarDivertAppPage1ViewModel {
    return self.viewModel as! MySolarDivertAppPage1ViewModel
  }

  @IBOutlet private var dateSegmentedControl: UISegmentedControl!
  @IBOutlet private var houseLabelView: AppTitleAndValueView!
  @IBOutlet private var divertLabelView: AppTitleAndValueView!
  @IBOutlet private var totalUseLabelView: AppTitleAndValueView!
  @IBOutlet private var importLabelView: AppTitleAndValueView!
  @IBOutlet private var solarLabelView: AppTitleAndValueView!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var solarBoxView: AppBoxesFeedView!
  @IBOutlet private var gridBoxView: AppBoxesFeedView!
  @IBOutlet private var divertBoxView: AppBoxesFeedView!
  @IBOutlet private var houseBoxView: AppBoxesFeedView!
  @IBOutlet private var solarToDivertArrowView: AppBoxesArrowView!
  @IBOutlet private var solarToHouseArrowView: AppBoxesArrowView!
  @IBOutlet private var solarToGridArrowView: AppBoxesArrowView!
  @IBOutlet private var gridToHouseArrowView: AppBoxesArrowView!

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Apps.MySolarDivert

    self.houseLabelView.alignment = .left
    self.houseLabelView.valueColor = EmonCMSColors.Apps.House
    self.divertLabelView.alignment = .center
    self.divertLabelView.valueColor = EmonCMSColors.Apps.Divert
    self.totalUseLabelView.alignment = .right
    self.totalUseLabelView.valueColor = EmonCMSColors.Apps.Use
    self.importLabelView.alignment = .left
    self.importLabelView.valueColor = EmonCMSColors.Apps.Grid
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
      .map { $0?.houseNow }
      .map(powerFormat)
      .assign(to: \.value, on: self.houseLabelView)
      .store(in: &self.cancellables)

    self.typedViewModel.$data
      .map { $0?.divertNow }
      .map(powerFormat)
      .assign(to: \.value, on: self.divertLabelView)
      .store(in: &self.cancellables)

    self.typedViewModel.$data
      .map { $0?.totalUseNow }
      .map(powerFormat)
      .assign(to: \.value, on: self.totalUseLabelView)
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

extension MySolarDivertAppPage1ViewController {
  private func setupCharts() {
    ChartHelpers.setupAppLineChart(self.lineChart)
  }

  private func updateLineChartData(_ dataPoints: (use: [DataPoint<Double>], solar: [DataPoint<Double>],
                                                  divert: [DataPoint<Double>])?)
  {
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
      ChartHelpers.updateLineChart(withData: data, forSet: 2, withPoints: dataPoints.divert) {
        $0.setColor(EmonCMSColors.Chart.Orange)
        $0.fillColor = EmonCMSColors.Chart.Orange
      }

      self.lineChart.leftAxis.axisMinimum = min(data.yMin, 0)
    } else {
      self.lineChart.data = nil
    }

    self.lineChart.notifyDataSetChanged()
  }
}

extension MySolarDivertAppPage1ViewController {
  private func setupBoxView() {
    self.solarBoxView.backgroundColor = EmonCMSColors.Apps.Solar
    self.solarBoxView.name = "SOLAR"
    self.solarBoxView.unit = "kWh"

    self.divertBoxView.backgroundColor = EmonCMSColors.Apps.Divert
    self.divertBoxView.name = "DIVERT"
    self.divertBoxView.unit = "kWh"

    self.gridBoxView.backgroundColor = EmonCMSColors.Apps.Grid
    self.gridBoxView.name = "GRID"
    self.gridBoxView.unit = "kWh"

    self.houseBoxView.backgroundColor = EmonCMSColors.Apps.House
    self.houseBoxView.name = "HOUSE"
    self.houseBoxView.unit = "kWh"

    self.solarToDivertArrowView.unit = "kWh"
    self.solarToDivertArrowView.direction = .down

    self.solarToHouseArrowView.unit = "kWh"
    self.solarToHouseArrowView.direction = .down

    self.solarToGridArrowView.unit = "kWh"
    self.solarToGridArrowView.direction = .right

    self.gridToHouseArrowView.unit = "kWh"
    self.gridToHouseArrowView.direction = .down
  }

  private func updateBoxViewData(_ dataPoints: (use: [DataPoint<Double>], solar: [DataPoint<Double>],
                                                divert: [DataPoint<Double>])?)
  {
    guard let dataPoints = dataPoints else { return }

    let use = dataPoints.use
    let solar = dataPoints.solar
    let divert = dataPoints.divert
    guard use.count > 0, solar.count > 0, divert.count > 0 else { return }

    var totalHouse = 0.0
    var totalDivert = 0.0
    var totalSolar = 0.0
    var totalImport = 0.0
    var solarToGrid = 0.0
    var solarToDivert = 0.0
    var solarToHouse = 0.0
    var gridToHouse = 0.0

    DataPoint.merge(pointsFrom: [use, solar, divert]) { timeDelta, _, values in
      let wattsToKWH = { (power: Double) -> Double in
        (power / 1000.0) * (timeDelta / 3600.0)
      }

      let useValue = wattsToKWH(values[0])
      let solarValue = wattsToKWH(values[1])
      let divertValue = wattsToKWH(values[2])
      let houseUseValue = useValue - divertValue
      let importValue = useValue - solarValue

      totalHouse += houseUseValue
      totalSolar += solarValue
      totalImport += importValue
      totalDivert += divertValue
      solarToDivert += divertValue

      if importValue > 0 { // Importing
        gridToHouse += importValue
        solarToHouse += solarValue
      } else { // Exporting
        solarToGrid += -importValue
        solarToHouse += houseUseValue
      }
    }

    self.solarBoxView.value = totalSolar
    self.gridBoxView.value = totalImport
    self.divertBoxView.value = totalDivert
    self.houseBoxView.value = totalHouse
    self.solarToGridArrowView.value = solarToGrid
    self.solarToDivertArrowView.value = solarToDivert
    self.solarToHouseArrowView.value = solarToHouse
    self.gridToHouseArrowView.value = gridToHouse
  }
}
