//
//  MySolarAppPage2ViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 29/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import Charts

final class MySolarAppPage2ViewController: AppPageViewController {

  var typedViewModel: MySolarAppPage2ViewModel {
    return self.viewModel as! MySolarAppPage2ViewModel
  }

  @IBOutlet private var dateSegmentedControl: UISegmentedControl!
  @IBOutlet private var useBarChart: BarChartView!
  @IBOutlet private var solarBarChart: BarChartView!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupCharts()
    self.setupBindings()
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
    self.dateSegmentedControl.rx.selectedSegmentIndex
      .startWith(self.dateSegmentedControl.selectedSegmentIndex)
      .map {
        DateRange.fromWMYSegmentedControlIndex($0)
      }
      .bind(to: self.viewModel.dateRange)
      .disposed(by: self.disposeBag)

    self.typedViewModel.data
      .map { $0?.barChartData }
      .drive(onNext: { [weak self] dataPoints in
        guard let self = self else { return }
        self.updateBarChartData(dataPoints)
      })
      .disposed(by: self.disposeBag)
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
