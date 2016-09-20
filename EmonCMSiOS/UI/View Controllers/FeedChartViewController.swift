//
//  FeedChartViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import Charts
import Former

class FeedChartViewController: FormViewController {

  var viewModel: FeedChartViewModel!

  private var chartRow: CustomRowFormer<ChartCell<LineChartView>>!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.viewModel.name
      .drive(self.rx.title)
      .addDisposableTo(self.disposeBag)

    self.setupFormer()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active.value = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    self.viewModel.active.value = false
  }

  private func setupFormer() {
    // Chart
    let chartRow = CustomRowFormer<ChartCell<LineChartView>>(instantiateType: .Class) {
      $0.chartView.dragEnabled = false
      $0.chartView.pinchZoomEnabled = false
      $0.chartView.setScaleEnabled(false)
      $0.chartView.descriptionText = ""
      $0.chartView.drawGridBackgroundEnabled = false
      $0.chartView.legend.enabled = false
      $0.chartView.rightAxis.enabled = false

      let xAxis = $0.chartView.xAxis
      xAxis.drawGridLinesEnabled = false
      xAxis.labelPosition = .bottom
      xAxis.valueFormatter = ChartXAxisDateFormatter()

      let yAxis = $0.chartView.leftAxis
      yAxis.drawGridLinesEnabled = false
      yAxis.labelPosition = .outsideChart

      let dataSet = LineChartDataSet(yVals: nil, label: nil)
      dataSet.valueTextColor = .lightGray
      dataSet.fillColor = .black
      dataSet.setColor(.black)
      dataSet.drawCirclesEnabled = false
      dataSet.drawFilledEnabled = true
      dataSet.drawValuesEnabled = false

      let data = LineChartData()
      data.addDataSet(dataSet)
      $0.chartView.data = data
      }.configure {
        $0.rowHeight = 250
    }

    self.chartRow = chartRow
    let chartSection = SectionFormer(rowFormer: chartRow)

    // Date options
    let dateRangeTypeRow = SegmentedRowFormer<FormSegmentedCell>() { _ in
      }.configure {
        $0.segmentTitles = ["Absolute", "Relative", "Relative to now"]
        $0.selectedIndex = 0
      }

    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    dateFormatter.dateStyle = .medium

    let startDateRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
      $0.titleLabel.text = "Start"
      $0.titleLabel.font = .boldSystemFont(ofSize: 15)
      $0.displayLabel.font = .systemFont(ofSize: 15)
      }.inlineCellSetup {
        $0.datePicker.datePickerMode = .dateAndTime
      }.displayTextFromDate(dateFormatter.string)
    startDateRow.date = Date() - (8 * 60 * 60)

    let endDateRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
      $0.titleLabel.text = "End"
      $0.titleLabel.font = .boldSystemFont(ofSize: 15)
      $0.displayLabel.font = .systemFont(ofSize: 15)
      }.inlineCellSetup {
        $0.datePicker.datePickerMode = .dateAndTime
      }.displayTextFromDate(dateFormatter.string)
    endDateRow.date = Date()

    let dateRelativeRow = SegmentedRowFormer<FormSegmentedCell>() { _ in
      }.configure {
        $0.segmentTitles = ["1h", "8h", "D", "M", "Y"]
        $0.selectedIndex = 0
    }

    let optionsSection = SectionFormer(rowFormer: dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow)

    self.former.append(sectionFormer: chartSection, optionsSection)
    self.former.reload()

    let dateRangeTypeSignal = RowFormer.rx_observable(dateRangeTypeRow.onSegmentSelected)
      .map { $0.0 }
      .startWith(dateRangeTypeRow.selectedIndex)
      .do(onNext: { s in
        switch s {
        case 0:
          startDateRow.enabled = true
          endDateRow.enabled = true
          dateRelativeRow.enabled = false
        case 1:
          startDateRow.enabled = false
          endDateRow.enabled = true
          dateRelativeRow.enabled = true
        case 2:
          startDateRow.enabled = false
          endDateRow.enabled = false
          dateRelativeRow.enabled = true
        default:
          break
        }
      })
      .shareReplay(1)
    let startDateSignal = RowFormer.rx_observable(startDateRow.onDateChanged)
      .startWith(startDateRow.date)
      .shareReplay(1)
    let endDateSignal = RowFormer.rx_observable(endDateRow.onDateChanged)
      .startWith(endDateRow.date)
      .shareReplay(1)
    let dateRelativeSignal = RowFormer.rx_observable(dateRelativeRow.onSegmentSelected)
      .map { $0.0 }
      .startWith(dateRelativeRow.selectedIndex)
      .map { segment -> TimeInterval in
        switch segment {
        case 0:
          return 1 * 3600
        case 1:
          return 8 * 3600
        case 2:
          return 24 * 3600
        case 3:
          return 30 * 24 * 3600
        case 4:
          return 365 * 24 * 3600
        default:
          return 0
        }
      }
      .shareReplay(1)

    let dateRangeSignal = Observable
      .combineLatest(dateRangeTypeSignal, startDateSignal, endDateSignal, dateRelativeSignal) {
        dateRangeType, startDate, endDate, dateRelative -> FeedChartParameters.DateRangeType in
        switch dateRangeType {
        case 0:
          return .absolute(startDate, endDate)
        case 1:
          return .relative(endDate, dateRelative)
        case 2:
          return .relativeToNow(dateRelative)
        default:
          return .absolute(startDate, endDate)
        }
    }

    dateRangeSignal
      .map { FeedChartParameters(dateRange: $0) }
      .bindTo(self.viewModel.updateParameters)
      .addDisposableTo(self.disposeBag)
  }

  private func setupBindings() {
    self.viewModel.dataPoints
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }

        let chartView = strongSelf.chartRow.cell.chartView

        guard let data = chartView.data,
          let dataSet = data.getDataSetByIndex(0) else {
            return
        }

        data.xVals = []
        dataSet.clear()

        for (i, point) in dataPoints.enumerated() {
          data.addXValue("\(point.time.timeIntervalSince1970)")

          let yDataEntry = ChartDataEntry(value: point.value, xIndex: i)
          data.addEntry(yDataEntry, dataSetIndex: 0)
        }

        data.notifyDataChanged()
        chartView.notifyDataSetChanged()
      })
      .addDisposableTo(self.disposeBag)
  }

}
