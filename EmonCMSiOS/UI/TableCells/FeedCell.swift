//
//  FeedCell.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 26/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

import Charts

final class FeedCell: UITableViewCell {
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var valueLabel: UILabel!
  @IBOutlet var timeLabel: UILabel!
  @IBOutlet var activityCircle: UIView!
  @IBOutlet var disclosureButton: UIButton!

  @IBOutlet private var mainViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet private var chartViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet private var chartContainerView: UIView!
  @IBOutlet private var chartView: LineChartView!
  @IBOutlet private var chartSpinner: UIActivityIndicatorView!
  @IBOutlet private var chartSegmentedControl: UISegmentedControl!

  let chartViewModel = CurrentValueSubject<FeedChartViewModel?, Never>(nil)
  let prepareForReuseSignal = PassthroughSubject<Void, Never>()

  private var cancellables = Set<AnyCancellable>()

  override func layoutSubviews() {
    super.layoutSubviews()
    self.activityCircle.layer.cornerRadius = self.activityCircle.bounds.width / 2
  }

  override func awakeFromNib() {
    self.chartContainerView.accessibilityIdentifier = AccessibilityIdentifiers.FeedList.ChartContainer

    self.setupChartView()
    self.setupChartBindings()
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    let colour = self.activityCircle.backgroundColor
    super.setSelected(selected, animated: animated)
    self.activityCircle.backgroundColor = colour
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    self.prepareForReuseSignal.send(())
  }

  private func setupChartBindings() {
    self.chartViewModel
      .map { chartViewModel -> AnyPublisher<Bool, Never> in
        if let chartViewModel = chartViewModel {
          return chartViewModel.isRefreshing.throttle(for: 0.3, scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
        } else {
          return Empty<Bool, Never>(completeImmediately: false).eraseToAnyPublisher()
        }
      }
      .switchToLatest()
      .sink { [weak self] refreshing in
        guard let self = self else { return }

        if refreshing {
          self.chartSpinner.startAnimating()
          self.chartView.alpha = 0.5
        } else {
          self.chartSpinner.stopAnimating()
          self.chartView.alpha = 1.0
        }
      }
      .store(in: &self.cancellables)

    self.chartViewModel
      .removeDuplicates(by: { $0 === $1 })
      .sink { [weak self] chartViewModel in
        guard let self = self else { return }

        let expanded = chartViewModel != nil

        self.mainViewBottomConstraint.isActive = !expanded
        self.chartViewBottomConstraint.isActive = expanded
        self.setNeedsLayout()
      }
      .store(in: &self.cancellables)

    self.chartViewModel
      .map { [weak self] chartViewModel -> AnyPublisher<Void, Never> in
        var cancellables = Set<AnyCancellable>()

        if let self = self, let chartViewModel = chartViewModel {
          let cancellable1 = self.chartSegmentedControl.publisher(for: \.selectedSegmentIndex)
            .map {
              DateRange.from1h8hDMYSegmentedControlIndex($0)
            }
            .assign(to: \.dateRange, on: chartViewModel)
          cancellables.insert(cancellable1)

          let cancellable2 = chartViewModel.$dataPoints
            .sink { [weak self] dataPoints in
              guard let self = self else { return }

              let chartView = self.chartView!

              guard !dataPoints.isEmpty else {
                chartView.data = nil
                chartView.notifyDataSetChanged()
                return
              }

              let dataSet = LineChartDataSet(entries: [], label: nil)
              dataSet.valueTextColor = .systemGray3
              dataSet.fillColor = .label
              dataSet.setColor(.label)
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
          chartViewModel.active = true
          cancellables.insert(cancellable2)
        }

        return Empty<Void, Never>(completeImmediately: false)
          .handleEvents(receiveCancel: {
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
          })
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .sink { _ in }
      .store(in: &self.cancellables)
  }

  private func setupChartView() {
    let chartView = self.chartView!
    ChartHelpers.setupDefaultLineChart(chartView)
  }
}
