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

final class MyElectricAppViewController: AppPageViewController {

  var typedViewModel: MyElectricAppViewModel {
    return self.viewModel as! MyElectricAppViewModel
  }

  @IBOutlet private var dateSegmentedControl: UISegmentedControl!
  @IBOutlet private var powerLabelView: AppTitleAndValueView!
  @IBOutlet private var usageTodayLabelView: AppTitleAndValueView!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var barChart: BarChartView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Apps.MyElectric

    self.powerLabelView.alignment = .left
    self.powerLabelView.valueColor = EmonCMSColors.Apps.Use
    self.usageTodayLabelView.alignment = .right
    self.usageTodayLabelView.valueColor = EmonCMSColors.Apps.Use

    self.setupCharts()
    self.setupBindings()
  }

  private func setupBindings() {
    self.dateSegmentedControl.rx.selectedSegmentIndex
      .startWith(self.dateSegmentedControl.selectedSegmentIndex)
      .map {
        DateRange.from1h8hDMYSegmentedControlIndex($0)
      }
      .bind(to: self.typedViewModel.dateRange)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
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
      .drive(self.powerLabelView.rx.value)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
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
      .drive(self.usageTodayLabelView.rx.value)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
      .map { $0?.lineChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateLineChartData(dataPoints)
        })
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
      .map { $0?.barChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }
        strongSelf.updateBarChartData(dataPoints)
        })
      .disposed(by: self.disposeBag)
  }

}

extension MyElectricAppViewController {

  private func setupCharts() {
    ChartHelpers.setupAppLineChart(self.lineChart)
    ChartHelpers.setupAppBarChart(self.barChart)
  }

  private func updateLineChartData(_ dataPoints: [DataPoint<Double>]?) {
    if let dataPoints = dataPoints {
      let data = self.lineChart.lineData ?? LineChartData()
      self.lineChart.data = data

      ChartHelpers.updateLineChart(withData: data, forSet: 0, withPoints: dataPoints) {
        $0.setColor(EmonCMSColors.Chart.Blue)
        $0.fillColor = EmonCMSColors.Chart.Blue
      }

      self.lineChart.leftAxis.axisMinimum = min(data.yMin, 0)
    } else {
      self.lineChart.data = nil
    }

    self.lineChart.notifyDataSetChanged()
  }

  private func updateBarChartData(_ dataPoints: [DataPoint<Double>]?) {
    if let dataPoints = dataPoints {
      let data = self.barChart.barData ?? BarChartData()
      self.barChart.data = data

      ChartHelpers.updateBarChart(withData: data, forSet: 0, withPoints: dataPoints) {
        $0.setColor(EmonCMSColors.Chart.Blue)
      }
    } else {
      self.barChart.data = nil
    }

    self.barChart.notifyDataSetChanged()
  }

}
