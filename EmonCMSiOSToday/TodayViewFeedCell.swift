//
//  TodayViewFeedCell.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import Charts

final class TodayViewFeedCell: UITableViewCell {

  @IBOutlet var feedNameLabel: UILabel!
  @IBOutlet var accountNameLabel: UILabel!
  @IBOutlet var feedValueLabel: UILabel!
  @IBOutlet var chartView: LineChartView!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.setupChart()
  }

  func updateChart(withData data: [DataPoint<Double>]) {
    let entries = data.map {
      ChartDataEntry(x: $0.time.timeIntervalSince1970, y: $0.value)
    }

    let data = self.chartView.lineData ?? LineChartData()
    self.chartView.data = data

    if let dataSet = data.getDataSetByIndex(0) {
      dataSet.clear()
      for entry in entries {
        _ = dataSet.addEntry(entry)
      }

      dataSet.notifyDataSetChanged()
      data.notifyDataChanged()
    } else {
      let dataSet = LineChartDataSet(entries: entries, label: nil)
      dataSet.setColor(EmonCMSColors.Chart.Blue)
      dataSet.valueTextColor = .black
      dataSet.drawFilledEnabled = false
      dataSet.drawCirclesEnabled = false
      dataSet.drawValuesEnabled = false
      dataSet.highlightEnabled = false
      dataSet.fillFormatter = DefaultFillFormatter(block: { (_, _) in 0 })

      data.addDataSet(dataSet)
    }

    self.chartView.notifyDataSetChanged()
  }

  private func setupChart() {
    let lineChart = self.chartView!
    lineChart.drawGridBackgroundEnabled = false
    lineChart.legend.enabled = false
    lineChart.rightAxis.enabled = false
    lineChart.chartDescription = nil
    lineChart.noDataText = "Loading data\u{2026}"
    lineChart.noDataTextColor = .black
    lineChart.isUserInteractionEnabled = false

    let xAxis = lineChart.xAxis
    xAxis.drawAxisLineEnabled = false
    xAxis.drawGridLinesEnabled = false
    xAxis.drawLabelsEnabled = false

    let yAxis = lineChart.leftAxis
    yAxis.drawTopYLabelEntryEnabled = false
    yAxis.drawZeroLineEnabled = false
    yAxis.drawGridLinesEnabled = false
    yAxis.drawAxisLineEnabled = false
    yAxis.drawLabelsEnabled = false
  }

}
