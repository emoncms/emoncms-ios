//
//  ChartHelpers.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import Charts
import CoreMedia

final class ChartHelpers {
  static func setupDefaultLineChart(_ lineChart: LineChartView) {
    lineChart.noDataText = "No data"
    lineChart.dragEnabled = false
    lineChart.pinchZoomEnabled = false
    lineChart.highlightPerTapEnabled = false
    lineChart.setScaleEnabled(false)
    lineChart.drawGridBackgroundEnabled = false
    lineChart.legend.enabled = false
    lineChart.rightAxis.enabled = false

    let xAxis = lineChart.xAxis
    xAxis.drawGridLinesEnabled = false
    xAxis.labelPosition = .bottom
    xAxis.valueFormatter = ChartDateValueFormatter(.auto(nil))

    let yAxis = lineChart.leftAxis
    yAxis.drawGridLinesEnabled = false
    yAxis.labelPosition = .outsideChart
    yAxis.drawZeroLineEnabled = true

    let yAxisFormatter = NumberFormatter()
    yAxisFormatter.minimumIntegerDigits = 1
    let valueFormatter = DefaultAxisValueFormatter.with { value, axis -> String in
      guard let axis = axis else { return "" }
      let range = axis.axisRange
      let count = axis.entryCount
      let perLabel = range / Double(count)
      let decimals: Int
      if perLabel.isNaN || perLabel <= 0 {
        decimals = 0
      } else if perLabel > 1 {
        decimals = 0
      } else {
        decimals = -Int(floor(log10(perLabel)))
      }
      yAxisFormatter.minimumFractionDigits = decimals
      return yAxisFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    yAxis.valueFormatter = valueFormatter
  }

  static func setupAppLineChart(_ lineChart: LineChartView) {
    lineChart.drawGridBackgroundEnabled = false
    lineChart.legend.enabled = false
    lineChart.rightAxis.enabled = false
    lineChart.noDataText = "Loading data\u{2026}"
    lineChart.noDataTextColor = .label
    lineChart.isUserInteractionEnabled = false

    let xAxis = lineChart.xAxis
    xAxis.drawAxisLineEnabled = false
    xAxis.drawGridLinesEnabled = false
    xAxis.drawLabelsEnabled = true
    xAxis.labelPosition = .bottom
    xAxis.labelTextColor = .label
    xAxis.valueFormatter = ChartDateValueFormatter(.auto(nil))
    xAxis.granularity = 3600

    let yAxis = lineChart.leftAxis
    yAxis.labelPosition = .insideChart
    yAxis.drawTopYLabelEntryEnabled = false
    yAxis.drawZeroLineEnabled = true
    yAxis.drawGridLinesEnabled = false
    yAxis.drawAxisLineEnabled = false
    yAxis.labelTextColor = .label
    yAxis.spaceTop = 0.01
    yAxis.spaceBottom = 0.01
  }

  static func setupAppBarChart(_ barChart: BarChartView) {
    barChart.drawGridBackgroundEnabled = false
    barChart.legend.enabled = false
    barChart.leftAxis.enabled = false
    barChart.rightAxis.enabled = false
    barChart.noDataText = "Loading data\u{2026}"
    barChart.noDataTextColor = .label
    barChart.isUserInteractionEnabled = false
    barChart.extraBottomOffset = 0
    barChart.drawValueAboveBarEnabled = true

    let xAxis = barChart.xAxis
    xAxis.avoidFirstLastClippingEnabled = true
    xAxis.labelPosition = .bottom
    xAxis.labelTextColor = .label
    xAxis.valueFormatter = DayRelativeToTodayValueFormatter()
    xAxis.drawGridLinesEnabled = false
    xAxis.drawAxisLineEnabled = false
    xAxis.drawLabelsEnabled = true
    xAxis.granularity = 1
    xAxis.labelCount = 14
  }

  static func updateLineChart(
    withData data: LineChartData,
    forSet setIndex: Int,
    withPoints points: [DataPoint<Double>],
    configureBlock: (_ set: LineChartDataSet) -> Void)
  {
    let entries = points.map {
      ChartDataEntry(x: $0.time.timeIntervalSince1970, y: $0.value)
    }

    if let dataSet = data.dataSet(at: setIndex) {
      dataSet.clear()
      for entry in entries {
        _ = dataSet.addEntry(entry)
      }

      dataSet.notifyDataSetChanged()
      data.notifyDataChanged()
    } else {
      let dataSet = LineChartDataSet(entries: entries)
      configureBlock(dataSet)
      dataSet.valueTextColor = .label
      dataSet.drawFilledEnabled = true
      dataSet.drawCirclesEnabled = false
      dataSet.drawValuesEnabled = false
      dataSet.highlightEnabled = false
      dataSet.fillFormatter = DefaultFillFormatter(block: { _, _ in 0 })

      data.append(dataSet)
    }
  }

  static func updateBarChart(
    withData data: BarChartData,
    forSet setIndex: Int,
    withPoints points: [DataPoint<Double>],
    configureBlock: (_ set: BarChartDataSet) -> Void)
  {
    var entries: [ChartDataEntry] = []
    for point in points {
      // 'x' here means the offset in days from 'today'
      let x = floor(point.time.timeIntervalSinceNow / 86400)
      let y = point.value

      let yDataEntry = BarChartDataEntry(x: x, y: y)
      entries.append(yDataEntry)
    }

    if let dataSet = data.dataSet(at: setIndex) {
      dataSet.clear()
      for entry in entries {
        _ = dataSet.addEntry(entry)
      }

      dataSet.notifyDataSetChanged()
      data.notifyDataChanged()
    } else {
      let dataSet = BarChartDataSet(entries: entries, label: "kWh")
      configureBlock(dataSet)
      dataSet.valueTextColor = .label

      data.append(dataSet)
    }
  }

  static func processKWHData(_ dataPoints: [DataPoint<Double>], padTo: Int,
                             interval: TimeInterval) -> [DataPoint<Double>]
  {
    guard dataPoints.count > 0 else { return [] }

    var deltaDataPoints: [DataPoint<Double>] = []

    // Calculate how many extra data points we need to get to the required padding.
    let extraPadding = padTo - (dataPoints.count - 1)
    if extraPadding > 0, let firstDataPoint = dataPoints.first {
      var time = firstDataPoint.time - (interval * Double(extraPadding - 1))

      // More than 1 padding points, these will all be zeros.
      if extraPadding > 1 {
        for _ in 2 ... extraPadding {
          deltaDataPoints.append(DataPoint<Double>(time: time, value: 0))
          time += interval
        }
      }

      // Last point to add has delta value of the value of the first input data point.
      deltaDataPoints.append(DataPoint<Double>(time: time, value: firstDataPoint.value))
    }

    // Now add all the deltas from the input
    var lastValue: Double = dataPoints.first?.value ?? 0
    for i in 1 ..< dataPoints.count {
      let thisDataPoint = dataPoints[i]
      let differenceValue = thisDataPoint.value - lastValue
      lastValue = thisDataPoint.value
      deltaDataPoints.append(DataPoint<Double>(time: thisDataPoint.time, value: differenceValue))
    }

    return deltaDataPoints
  }
}
