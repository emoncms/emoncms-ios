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

final class MyElectricAppViewController: AppViewController {

  var typedViewModel: MyElectricAppViewModel {
    return self.viewModel as! MyElectricAppViewModel
  }

  @IBOutlet private var powerLabel: UILabel!
  @IBOutlet private var usageTodayLabel: UILabel!
  @IBOutlet private var lineChart: LineChartView!
  @IBOutlet private var barChart: BarChartView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Apps.MyElectric

    self.setupCharts()
    self.setupBindings()
  }

  private func setupBindings() {
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
      .drive(self.powerLabel.rx.text)
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
      .drive(self.usageTodayLabel.rx.text)
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
      let data = (self.barChart.data as? BarChartData) ?? BarChartData()
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
