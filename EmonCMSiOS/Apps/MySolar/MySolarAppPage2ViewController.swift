//
//  MySolarAppPage2ViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 29/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit
import Combine

import Charts

final class MySolarAppPage2ViewController: AppPageViewController {

  var typedViewModel: MySolarAppPage2ViewModel {
    return self.viewModel as! MySolarAppPage2ViewModel
  }

  @IBOutlet private var dateSegmentedControl: UISegmentedControl!
  @IBOutlet private var useBarChart: BarChartView!
  @IBOutlet private var solarBarChart: BarChartView!

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupCharts()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    self.viewModel.active = false
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

extension MySolarAppPage2ViewController {

  private func setupCharts() {
    ChartHelpers.setupAppBarChart(self.useBarChart)
    ChartHelpers.setupAppBarChart(self.solarBarChart)
  }

  private func updateBarChartData(_ dataPoints: (use: [DataPoint<Double>], solar: [DataPoint<Double>])?) {
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
    } else {
      self.useBarChart.data = nil
      self.solarBarChart.data = nil
    }

    self.useBarChart.notifyDataSetChanged()
    self.solarBarChart.notifyDataSetChanged()
  }

}
