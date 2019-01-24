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

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Apps.MySolar

    self.useLabelView.alignment = .left
    self.importLabelView.alignment = .center
    self.solarLabelView.alignment = .right

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
      .drive(self.useLabelView.rx.value)
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
      .drive(self.importLabelView.rx.title)
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
      .drive(self.importLabelView.rx.value)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
      .map { $0?.solarNow }
      .map(powerFormat)
      .drive(self.solarLabelView.rx.value)
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
    ChartHelpers.setupAppLineChart(self.lineChart)
  }

  private func updateLineChartData(_ dataPoints: (use: [DataPoint], solar: [DataPoint])?) {
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
    } else {
      self.lineChart.data = nil
    }

    self.lineChart.notifyDataSetChanged()
  }

}

extension MySolarAppViewController {

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

  private func updateBoxViewData(_ dataPoints: (use: [DataPoint], solar: [DataPoint])?) {
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

    DataPoint.merge(pointsFrom: [use, solar]) { (timeDelta, _, values) in
      let wattsToKWH = { (power: Double) -> Double in
        return (power / 1000.0) * (timeDelta / 3600.0)
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
        solarToGrid += (-importValue)
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
