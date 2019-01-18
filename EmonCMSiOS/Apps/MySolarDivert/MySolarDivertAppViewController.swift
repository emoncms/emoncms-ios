//
//  MySolarDivertAppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import Charts

final class MySolarDivertAppViewController: AppViewController {

  var typedViewModel: MySolarDivertAppViewModel {
    return self.viewModel as! MySolarDivertAppViewModel
  }

  @IBOutlet private var houseLabel: UILabel!
  @IBOutlet private var divertLabel: UILabel!
  @IBOutlet private var totalUseLabel: UILabel!
  @IBOutlet private var importTitleLabel: UILabel!
  @IBOutlet private var importLabel: UILabel!
  @IBOutlet private var solarLabel: UILabel!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var solarBoxView: AppBoxesFeedView!
  @IBOutlet private var gridBoxView: AppBoxesFeedView!
  @IBOutlet private var divertBoxView: AppBoxesFeedView!
  @IBOutlet private var houseBoxView: AppBoxesFeedView!
  @IBOutlet private var solarToDivertArrowView: AppBoxesArrowView!
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
      .map { $0?.houseNow }
      .map(powerFormat)
      .drive(self.houseLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
      .map { $0?.divertNow }
      .map(powerFormat)
      .drive(self.divertLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
      .map { $0?.totalUseNow }
      .map(powerFormat)
      .drive(self.totalUseLabel.rx.text)
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

extension MySolarDivertAppViewController {

  private func setupCharts() {
    ChartHelpers.setupAppLineChart(self.lineChart)
  }

  private func updateLineChartData(_ dataPoints: (use: [DataPoint], solar: [DataPoint], divert: [DataPoint])?) {
    if let dataPoints = dataPoints {
      let data = self.lineChart.lineData ?? LineChartData()
      self.lineChart.data = data

      var houseUse = [DataPoint]()
      let bigDivert = dataPoints.use // We can't do a stacked line chart, so we're faking it
      DataPoint.merge(pointsFrom: [dataPoints.use, dataPoints.divert]) { (_, time, values) in
        houseUse.append(DataPoint(time: time, value: (values[0] - values[1])))
      }

      ChartHelpers.updateLineChart(withData: data, forSet: 0, withPoints: bigDivert) {
        $0.setColor(EmonCMSColors.Chart.Orange)
        $0.fillColor = EmonCMSColors.Chart.Orange
      }
      ChartHelpers.updateLineChart(withData: data, forSet: 1, withPoints: houseUse) {
        $0.setColor(EmonCMSColors.Chart.Blue)
        $0.fillColor = EmonCMSColors.Chart.Blue
      }
      ChartHelpers.updateLineChart(withData: data, forSet: 2, withPoints: dataPoints.solar) {
        $0.setColor(EmonCMSColors.Chart.Yellow)
        $0.fillColor = EmonCMSColors.Chart.Yellow
      }
    } else {
      self.lineChart.data = nil
    }

    self.lineChart.notifyDataSetChanged()
  }

}

extension MySolarDivertAppViewController {

  private func setupBoxView() {
    self.solarBoxView.backgroundColor = EmonCMSColors.Apps.Solar
    self.solarBoxView.feedName = "SOLAR"
    self.solarBoxView.feedUnit = "kWh"

    self.divertBoxView.backgroundColor = EmonCMSColors.Apps.Divert
    self.divertBoxView.feedName = "DIVERT"
    self.divertBoxView.feedUnit = "kWh"

    self.gridBoxView.backgroundColor = EmonCMSColors.Apps.Grid
    self.gridBoxView.feedName = "GRID"
    self.gridBoxView.feedUnit = "kWh"

    self.houseBoxView.backgroundColor = EmonCMSColors.Apps.House
    self.houseBoxView.feedName = "HOUSE"
    self.houseBoxView.feedUnit = "kWh"

    self.solarToDivertArrowView.unit = "kWh"
    self.solarToDivertArrowView.direction = .down

    self.solarToHouseArrowView.unit = "kWh"
    self.solarToHouseArrowView.direction = .down

    self.solarToGridArrowView.unit = "kWh"
    self.solarToGridArrowView.direction = .right

    self.gridToHouseArrowView.unit = "kWh"
    self.gridToHouseArrowView.direction = .down
  }

  private func updateBoxViewData(_ dataPoints: (use: [DataPoint], solar: [DataPoint], divert: [DataPoint])?) {
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

    DataPoint.merge(pointsFrom: [use, solar, divert]) { (timeDelta, _, values) in
      let wattsToKWH = { (power: Double) -> Double in
        return (power / 1000.0) * (timeDelta / 3600.0)
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
        solarToGrid += (-importValue)
        solarToHouse += houseUseValue
      }
    }

    self.solarBoxView.feedValue = totalSolar
    self.gridBoxView.feedValue = totalImport
    self.divertBoxView.feedValue = totalDivert
    self.houseBoxView.feedValue = totalHouse
    self.solarToGridArrowView.value = solarToGrid
    self.solarToDivertArrowView.value = solarToDivert
    self.solarToHouseArrowView.value = solarToHouse
    self.gridToHouseArrowView.value = gridToHouse
  }

}
