//
//  ChartHelpers.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import Charts

final class ChartHelpers {

  static func setupDefaultLineChart(_ lineChart: LineChartView) {
    lineChart.noDataText = "No data"
    lineChart.dragEnabled = false
    lineChart.pinchZoomEnabled = false
    lineChart.highlightPerTapEnabled = false
    lineChart.setScaleEnabled(false)
    lineChart.chartDescription = nil
    lineChart.drawGridBackgroundEnabled = false
    lineChart.legend.enabled = false
    lineChart.rightAxis.enabled = false

    let xAxis = lineChart.xAxis
    xAxis.drawGridLinesEnabled = false
    xAxis.labelPosition = .bottom
    xAxis.valueFormatter = ChartDateValueFormatter(.auto)

    let yAxis = lineChart.leftAxis
    yAxis.drawGridLinesEnabled = false
    yAxis.labelPosition = .outsideChart
    yAxis.drawZeroLineEnabled = true

    let yAxisFormatter = NumberFormatter()
    yAxisFormatter.minimumIntegerDigits = 1
    yAxisFormatter.minimumSignificantDigits = 2
    yAxis.valueFormatter = DefaultAxisValueFormatter(formatter: yAxisFormatter)
  }

  static func setupAppLineChart(_ lineChart: LineChartView) {
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
    yAxis.axisMinimum = 0
  }

  static func setupAppBarChart(_ barChart: BarChartView) {
    barChart.drawGridBackgroundEnabled = false
    barChart.legend.enabled = false
    barChart.leftAxis.enabled = false
    barChart.rightAxis.enabled = false
    barChart.chartDescription = nil
    barChart.noDataText = "Loading data..."
    barChart.noDataTextColor = .black
    barChart.isUserInteractionEnabled = false
    barChart.extraBottomOffset = 0
    barChart.drawValueAboveBarEnabled = true

    let xAxis = barChart.xAxis
    xAxis.labelPosition = .bottom
    xAxis.labelTextColor = .black
    xAxis.valueFormatter = DayRelativeToTodayValueFormatter()
    xAxis.drawGridLinesEnabled = false
    xAxis.drawAxisLineEnabled = false
    xAxis.drawLabelsEnabled = true
    xAxis.granularity = 1
    xAxis.labelCount = 14
  }

  static func updateLineChart(withData data: LineChartData, forSet setIndex: Int, withPoints points: [DataPoint<Double>], configureBlock: (_ set: LineChartDataSet) -> Void) {
    let entries = points.map {
      ChartDataEntry(x: $0.time.timeIntervalSince1970, y: $0.value)
    }

    if let dataSet = data.getDataSetByIndex(setIndex) {
      dataSet.clear()
      for entry in entries {
        _ = dataSet.addEntry(entry)
      }

      dataSet.notifyDataSetChanged()
      data.notifyDataChanged()
    } else {
      let dataSet = LineChartDataSet(values: entries, label: nil)
      configureBlock(dataSet)
      dataSet.valueTextColor = .black
      dataSet.drawFilledEnabled = true
      dataSet.drawCirclesEnabled = false
      dataSet.drawValuesEnabled = false
      dataSet.highlightEnabled = false
      dataSet.fillFormatter = DefaultFillFormatter(block: { (_, _) in 0 })

      data.addDataSet(dataSet)
    }
  }

  static func updateBarChart(withData data: BarChartData, forSet setIndex: Int, withPoints points: [DataPoint<Double>], configureBlock: (_ set: BarChartDataSet) -> Void) {
    var entries: [ChartDataEntry] = []
    for point in points {
      // 'x' here means the offset in days from 'today'
      let x = floor(point.time.timeIntervalSinceNow / 86400)
      let y = point.value

      let yDataEntry = BarChartDataEntry(x: x, y: y)
      entries.append(yDataEntry)
    }

    if let dataSet = data.getDataSetByIndex(setIndex) {
      dataSet.clear()
      for entry in entries {
        _ = dataSet.addEntry(entry)
      }

      dataSet.notifyDataSetChanged()
      data.notifyDataChanged()
    } else {
      let dataSet = BarChartDataSet(values: entries, label: "kWh")
      configureBlock(dataSet)
      dataSet.valueTextColor = .black

      data.addDataSet(dataSet)
    }
  }

}
