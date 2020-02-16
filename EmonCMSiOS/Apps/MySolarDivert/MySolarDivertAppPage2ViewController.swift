//
//  MySolarDivertAppPage2ViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

import Charts

final class MySolarDivertAppPage2ViewController: AppPageViewController {
  var typedViewModel: MySolarDivertAppPage2ViewModel {
    return self.viewModel as! MySolarDivertAppPage2ViewModel
  }

  @IBOutlet private var dateSegmentedControl: UISegmentedControl!
  @IBOutlet private var useBarChart: BarChartView!
  @IBOutlet private var solarBarChart: BarChartView!
  @IBOutlet private var divertBarChart: BarChartView!

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupCharts()
    self.setupBindings()
  }

  private func setupBindings() {
    self.dateSegmentedControl.publisher(for: \.selectedSegmentIndex)
      .map {
        DateRange.fromWMYSegmentedControlIndex($0)
      }
      .assign(to: \.dateRange, on: self.viewModel)
      .store(in: &self.cancellables)

    self.typedViewModel.$data
      .map { $0?.barChartData }
      .sink { [weak self] dataPoints in
        guard let self = self else { return }
        self.updateBarChartData(dataPoints)
      }
      .store(in: &self.cancellables)
  }
}

extension MySolarDivertAppPage2ViewController {
  private func setupCharts() {
    ChartHelpers.setupAppBarChart(self.useBarChart)
    ChartHelpers.setupAppBarChart(self.solarBarChart)
    ChartHelpers.setupAppBarChart(self.divertBarChart)
  }

  private func updateBarChartData(_ dataPoints: (use: [DataPoint<Double>], solar: [DataPoint<Double>],
                                                 divert: [DataPoint<Double>])?) {
    if let dataPoints = dataPoints {
      let useData = self.useBarChart.barData ?? BarChartData()
      self.useBarChart.data = useData

      ChartHelpers.updateBarChart(withData: useData, forSet: 0, withPoints: dataPoints.use) {
        $0.setColor(EmonCMSColors.Chart.Blue)
      }

      let solarData = self.solarBarChart.barData ?? BarChartData()
      self.solarBarChart.data = solarData

      ChartHelpers.updateBarChart(withData: solarData, forSet: 0, withPoints: dataPoints.solar) {
        $0.setColor(EmonCMSColors.Chart.Yellow)
      }

      let divertData = self.divertBarChart.barData ?? BarChartData()
      self.divertBarChart.data = divertData

      ChartHelpers.updateBarChart(withData: divertData, forSet: 0, withPoints: dataPoints.divert) {
        $0.setColor(EmonCMSColors.Chart.Orange)
      }
    } else {
      self.useBarChart.data = nil
      self.solarBarChart.data = nil
      self.divertBarChart.data = nil
    }

    self.useBarChart.notifyDataSetChanged()
    self.solarBarChart.notifyDataSetChanged()
    self.divertBarChart.notifyDataSetChanged()
  }
}
