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

  static func updateLineChart(withData data: LineChartData, forSet setIndex: Int, withPoints points: [DataPoint], configureBlock: (_ set: LineChartDataSet) -> Void) {
    var entries: [ChartDataEntry] = []
    for point in points {
      let x = point.time.timeIntervalSince1970
      let y = point.value

      let yDataEntry = ChartDataEntry(x: x, y: y)
      entries.append(yDataEntry)
    }

    if let dataSet = data.getDataSetByIndex(setIndex)
    {
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

}
