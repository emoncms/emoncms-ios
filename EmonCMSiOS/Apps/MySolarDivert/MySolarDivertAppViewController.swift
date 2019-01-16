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

final class MySolarDivertAppViewController: UIViewController {

  var viewModel: MySolarDivertAppViewModel!

  @IBOutlet private var mainView: UIView!
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
      .map { $0?.houseNow }
      .map(powerFormat)
      .drive(self.houseLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map { $0?.divertNow }
      .map(powerFormat)
      .drive(self.divertLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.viewModel.data
      .map { $0?.totalUseNow }
      .map(powerFormat)
      .drive(self.totalUseLabel.rx.text)
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

extension MySolarDivertAppViewController {

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

  private func updateLineChartData(_ dataPoints: (use: [DataPoint], solar: [DataPoint], divert: [DataPoint])?) {
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
      ChartHelpers.updateLineChart(withData: data, forSet: 2, withPoints: dataPoints.divert) {
        $0.setColor(EmonCMSColors.Chart.Orange)
        $0.fillColor = EmonCMSColors.Chart.Orange
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

    var lastTime: Date? = nil
    var useIndex = use.startIndex
    var solarIndex = solar.startIndex
    var divertIndex = divert.startIndex

    var totalHouse = 0.0
    var totalDivert = 0.0
    var totalSolar = 0.0
    var totalImport = 0.0
    var solarToGrid = 0.0
    var solarToDivert = 0.0
    var solarToHouse = 0.0
    var gridToHouse = 0.0

    while useIndex < use.endIndex && solarIndex < solar.endIndex && divertIndex < divert.endIndex {
      let usePoint = use[useIndex]
      let solarPoint = solar[solarIndex]
      let divertPoint = divert[divertIndex]

      let useTime = usePoint.time
      let solarTime = solarPoint.time
      let divertTime = divertPoint.time

      guard useTime == solarTime && useTime == divertTime else {
        if useTime < solarTime {
          useIndex = useIndex.advanced(by: 1)
        } else if solarTime < divertTime {
          solarIndex = solarIndex.advanced(by: 1)
        } else {
          divertIndex = divertIndex.advanced(by: 1)
        }
        lastTime = nil
        continue
      }

      defer {
        useIndex = useIndex.advanced(by: 1)
        solarIndex = solarIndex.advanced(by: 1)
        divertIndex = divertIndex.advanced(by: 1)
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
      let divertValue = wattsToKWH(divertPoint.value)
      let houseValue = useValue - divertValue
      let importValue = useValue - solarValue

      totalHouse += houseValue
      totalSolar += solarValue
      totalDivert += divertValue
      solarToDivert += divertValue

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
    self.divertBoxView.feedValue = totalDivert
    self.houseBoxView.feedValue = totalHouse
    self.solarToGridArrowView.value = solarToGrid
    self.solarToDivertArrowView.value = solarToDivert
    self.solarToHouseArrowView.value = solarToHouse
    self.gridToHouseArrowView.value = gridToHouse
  }

}
