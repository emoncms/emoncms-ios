//
//  FeedChartViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

import Charts
import Former

final class FeedChartViewController: FormViewController {
  var viewModel: FeedChartViewModel!

  private var chartRow: CustomRowFormer<ChartCell<LineChartView>>!

  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Chart"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.FeedChartView
    self.navigationItem.largeTitleDisplayMode = .never

    self.tableView.refreshControl = UIRefreshControl()

    self.setupFormer()
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

  private func setupFormer() {
    let chartRow = self.chartFormerSection()
    self.chartRow = chartRow

    let dateOptionsRows = self.dateOptionsFormerSection()
    self.bindDateRangeSectionRows(dateOptionsRows)
    let (dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow) = dateOptionsRows

    self.former
      .append(sectionFormer: SectionFormer(rowFormer: chartRow),
              SectionFormer(rowFormer: dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow))
  }

  private func chartFormerSection() -> CustomRowFormer<ChartCell<LineChartView>> {
    let chartRow = CustomRowFormer<ChartCell<LineChartView>>(instantiateType: .Class) {
      ChartHelpers.setupDefaultLineChart($0.chartView)
    }.configure {
      $0.rowHeight = 250
    }

    return chartRow
  }

  typealias DateOptionsRowTypes = (SegmentedRowFormer<FormSegmentedCell>,
                                   InlineDatePickerRowFormer<FormInlineDatePickerCell>,
                                   InlineDatePickerRowFormer<FormInlineDatePickerCell>,
                                   SegmentedRowFormer<FormSegmentedCell>)

  private func dateOptionsFormerSection() -> DateOptionsRowTypes {
    let startDateRange = self.viewModel.dateRange
    let (startDate, endDate) = startDateRange.calculateDates()

    let dateRangeTypeRow = SegmentedRowFormer<FormSegmentedCell>() {
      $0.titleLabel.text = "Time range type"
      $0.titleLabel.font = .boldSystemFont(ofSize: 15)
    }.configure {
      $0.segmentTitles = ["Absolute", "Relative"]
      let selectedIndex: Int
      switch startDateRange {
      case .absolute:
        selectedIndex = 0
      case .relative:
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
      let selectedIndex: Int?
      switch startDateRange {
      case .relative(let relativeTime):
        selectedIndex = DateRange.to1h8hDMYSegmentedControlIndex(relativeTime)
      default:
        selectedIndex = nil
      }
      $0.selectedIndex = selectedIndex ?? 0
    }

    return (dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow)
  }

  private func bindDateRangeSectionRows(_ rows: DateOptionsRowTypes) {
    let (dateRangeTypeRow, startDateRow, endDateRow, dateRelativeRow) = rows

    let dateRangeTypeSignal = RowFormer.publisher(dateRangeTypeRow.onSegmentSelected)
      .map { $0.0 }
      .prepend(dateRangeTypeRow.selectedIndex)
      .handleEvents(receiveOutput: { s in
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
    let startDateSignal = RowFormer.publisher(startDateRow.onDateChanged)
      .prepend(startDateRow.date)
    let endDateSignal = RowFormer.publisher(endDateRow.onDateChanged)
      .prepend(endDateRow.date)
    let dateRelativeSignal = RowFormer.publisher(dateRelativeRow.onSegmentSelected)
      .map { $0.0 }
      .prepend(dateRelativeRow.selectedIndex)

    let dateRangeSignal = Publishers
      .CombineLatest4(dateRangeTypeSignal, startDateSignal, endDateSignal, dateRelativeSignal)
      .map {
        dateRangeType, startDate, endDate, dateRelative -> DateRange in
        switch dateRangeType {
        case 1:
          return DateRange.from1h8hDMYSegmentedControlIndex(dateRelative)
        /* case 0: */
        default:
          return .absolute(startDate, endDate)
        }
      }

    dateRangeSignal
      .assign(to: \.dateRange, on: self.viewModel)
      .store(in: &self.cancellables)
  }

  private func setupBindings() {
    let refreshControl = self.tableView.refreshControl!

    refreshControl.publisher(for: .valueChanged)
      .becomeVoid()
      .subscribe(self.viewModel.refresh)
      .store(in: &self.cancellables)

    self.viewModel.isRefreshing
      .sink { refreshing in
        if refreshing {
          refreshControl.beginRefreshing()
        } else {
          refreshControl.endRefreshing()
        }
      }
      .store(in: &self.cancellables)

    self.viewModel.isRefreshing
      .throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
      .sink { [weak self] refreshing in
        guard let self = self else { return }

        let cell = self.chartRow.cell

        if refreshing {
          cell.spinner.startAnimating()
          cell.chartView.alpha = 0.5
        } else {
          cell.spinner.stopAnimating()
          cell.chartView.alpha = 1.0
        }
      }
      .store(in: &self.cancellables)

    self.viewModel.$dataPoints
      .sink { [weak self] dataPoints in
        guard let self = self else { return }

        let chartView = self.chartRow.cell.chartView

        guard !dataPoints.isEmpty else {
          chartView.data = nil
          chartView.notifyDataSetChanged()
          return
        }

        let dataSet = LineChartDataSet(entries: [], label: nil)
        dataSet.valueTextColor = .lightGray
        dataSet.fillColor = .black
        dataSet.setColor(.black)
        dataSet.drawCirclesEnabled = false
        dataSet.drawFilledEnabled = true
        dataSet.drawValuesEnabled = false
        dataSet.fillFormatter = DefaultFillFormatter(block: { _, _ in 0 })

        for point in dataPoints {
          let x = point.time.timeIntervalSince1970
          let y = point.value

          let yDataEntry = ChartDataEntry(x: x, y: y)
          dataSet.append(yDataEntry)
        }

        let data = LineChartData()
        data.addDataSet(dataSet)
        chartView.data = data

        chartView.notifyDataSetChanged()
      }
      .store(in: &self.cancellables)
  }
}
