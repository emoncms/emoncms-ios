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

final class FeedChartViewController: FormViewController {

  var viewModel: FeedChartViewModel!

  private var chartRow: CustomRowFormer<ChartCell<LineChartView>>!

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Chart"
    self.navigationItem.largeTitleDisplayMode = .never

    self.tableView.refreshControl = UIRefreshControl()

    self.setupFormer()
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

  private func setupFormer() {
    let chartRow = self.chartFormerSection()
    self.chartRow = chartRow

    let dateOptionsRows = self.dateOptionsFormerSection()
    self.bindDateRangeSectionRows(dateOptionsRows)
    let (dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow) = dateOptionsRows

    self.former.append(sectionFormer: SectionFormer(rowFormer: chartRow), SectionFormer(rowFormer: dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow))
  }

  private func chartFormerSection() -> CustomRowFormer<ChartCell<LineChartView>> {
    let chartRow = CustomRowFormer<ChartCell<LineChartView>>(instantiateType: .Class) {
      ChartHelpers.setupDefaultLineChart($0.chartView)
    }.configure {
        $0.rowHeight = 250
    }

    return chartRow
  }

  typealias DateOptionsRowTypes = (SegmentedRowFormer<FormSegmentedCell>, InlineDatePickerRowFormer<FormInlineDatePickerCell>, InlineDatePickerRowFormer<FormInlineDatePickerCell>, SegmentedRowFormer<FormSegmentedCell>)

  private func dateOptionsFormerSection() -> DateOptionsRowTypes {
    let startDateRange = self.viewModel.dateRange.value
    let (startDate, endDate) = startDateRange.calculateDates()

    let dateRangeTypeRow = SegmentedRowFormer<FormSegmentedCell>() {
      $0.titleLabel.text = "Time range type"
      $0.titleLabel.font = .boldSystemFont(ofSize: 15)
      }.configure {
        $0.segmentTitles = ["Absolute", "Relative"]
        let selectedIndex: Int
        switch startDateRange {
        case .absolute(_, _):
          selectedIndex = 0
        case .relative(_):
          selectedIndex = 1
        }
        $0.selectedIndex = selectedIndex
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
    startDateRow.date = startDate

    let endDateRow = InlineDatePickerRowFormer<FormInlineDatePickerCell>() {
      $0.titleLabel.text = "End"
      $0.titleLabel.font = .boldSystemFont(ofSize: 15)
      $0.displayLabel.font = .systemFont(ofSize: 15)
      }.inlineCellSetup {
        $0.datePicker.datePickerMode = .dateAndTime
      }.displayTextFromDate(dateFormatter.string)
    endDateRow.date = endDate

    let dateRelativeRow = SegmentedRowFormer<FormSegmentedCell>() {
      $0.titleLabel.text = "Relative time"
      $0.titleLabel.font = .boldSystemFont(ofSize: 15)
      }.configure {
        $0.segmentTitles = ["1h", "8h", "D", "M", "Y"]
        let selectedIndex: Int
        switch startDateRange {
        case .relative(let relativeTime):
          switch relativeTime {
          case .hour1:
            selectedIndex = 0
          case .hour8:
            selectedIndex = 1
          case .day:
            selectedIndex = 2
          case .month:
            selectedIndex = 3
          case .year:
            selectedIndex = 4
          }
        default:
          selectedIndex = 0
        }
        $0.selectedIndex = selectedIndex
    }

    return (dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow)
  }

  private func bindDateRangeSectionRows(_ rows: DateOptionsRowTypes) {
    let (dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow) = rows

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
          endDateRow.enabled = false
          dateRelativeRow.enabled = true
        default:
          break
        }
      })
      .share(replay: 1)
    let startDateSignal = RowFormer.rx_observable(startDateRow.onDateChanged)
      .startWith(startDateRow.date)
      .share(replay: 1)
    let endDateSignal = RowFormer.rx_observable(endDateRow.onDateChanged)
      .startWith(endDateRow.date)
      .share(replay: 1)
    let dateRelativeSignal = RowFormer.rx_observable(dateRelativeRow.onSegmentSelected)
      .map { $0.0 }
      .startWith(dateRelativeRow.selectedIndex)
      .share(replay: 1)

    let dateRangeSignal = Observable
      .combineLatest(dateRangeTypeSignal, startDateSignal, endDateSignal, dateRelativeSignal) {
        dateRangeType, startDate, endDate, dateRelative -> DateRange in
        switch dateRangeType {
        case 1:
          let relativeTime = DateRange.RelativeTime(rawValue: dateRelative) ?? .hour1
          return .relative(relativeTime)
        /*case 0:*/
        default:
          return .absolute(startDate, endDate)
        }
    }

    dateRangeSignal
      .bind(to: self.viewModel.dateRange)
      .disposed(by: self.disposeBag)
  }

  private func setupBindings() {
    let refreshControl = self.tableView.refreshControl!

    refreshControl.rx.controlEvent(.valueChanged)
      .bind(to: self.viewModel.refresh)
      .disposed(by: self.disposeBag)

    self.viewModel.isRefreshing
      .drive(refreshControl.rx.isRefreshing)
      .disposed(by: self.disposeBag)

    self.viewModel.isRefreshing
      .throttle(0.3)
      .drive(onNext: { [weak self] refreshing in
        guard let strongSelf = self else { return }

        let cell = strongSelf.chartRow.cell

        if refreshing {
          cell.spinner.startAnimating()
          cell.chartView.alpha = 0.5
        } else {
          cell.spinner.stopAnimating()
          cell.chartView.alpha = 1.0
        }
      })
      .disposed(by: self.disposeBag)

    self.viewModel.dataPoints
      .drive(onNext: { [weak self] dataPoints in
        guard let strongSelf = self else { return }

        let chartView = strongSelf.chartRow.cell.chartView

        guard !dataPoints.isEmpty else {
          chartView.data = nil
          chartView.notifyDataSetChanged()
          return
        }

        let dataSet = LineChartDataSet(values: [], label: nil)
        dataSet.valueTextColor = .lightGray
        dataSet.fillColor = .black
        dataSet.setColor(.black)
        dataSet.drawCirclesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.drawValuesEnabled = false
        dataSet.fillFormatter = DefaultFillFormatter(block: { (_, _) in 0 })

        for point in dataPoints {
          let x = point.time.timeIntervalSince1970
          let y = point.value

          let yDataEntry = ChartDataEntry(x: x, y: y)
          _ = dataSet.addEntry(yDataEntry)
        }

        let data = LineChartData()
        data.addDataSet(dataSet)
        chartView.data = data

        chartView.notifyDataSetChanged()
      })
      .disposed(by: self.disposeBag)
  }

}
