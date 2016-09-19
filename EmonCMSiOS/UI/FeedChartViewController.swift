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

class FeedChartViewController: UIViewController {

  var viewModel: FeedChartViewModel!

  @IBOutlet var chartView: LineChartView!
  @IBOutlet var timeSegmentedControl: UISegmentedControl!

  private let disposeBag = DisposeBag()
  private let visible = Variable<Bool>(false)

  override func viewDidLoad() {
    super.viewDidLoad()

    self.viewModel.name
      .drive(self.rx.title)
      .addDisposableTo(self.disposeBag)

    self.setupChart()
    self.setupBindings()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.visible.value = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(true)
    self.visible.value = false
  }

  private func setupChart() {
    self.chartView.dragEnabled = false
    self.chartView.descriptionText = ""
    self.chartView.drawGridBackgroundEnabled = false
    self.chartView.legend.enabled = false
    self.chartView.rightAxis.enabled = false

    let xAxis = self.chartView.xAxis
    xAxis.drawGridLinesEnabled = false
    xAxis.labelPosition = .bottom
    xAxis.valueFormatter = ChartXAxisDateFormatter()

    let yAxis = self.chartView.leftAxis
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
    self.chartView.data = data
  }

  private func setupBindings() {
    typealias ChartLimitData = (Date, Date, TimeInterval)

    let dateDifference: Observable<DateComponents> = self.timeSegmentedControl.rx.value
      .map { value in
        var dateComponents = DateComponents()

        switch value {
        case 0: // 1 hour
          dateComponents.hour = -1
        case 1: // 8 hours
          dateComponents.hour = -8
        case 2: // Day
          dateComponents.day = -1
        case 3: // Month
          dateComponents.month = -1
        case 4: // Year
          dateComponents.year = -1
        default:
          break
        }

        return dateComponents
      }
      .shareReplay(1)

    let chartWidth = self.chartView.rx.observe(CGRect.self, "bounds")
      .map { $0 ?? CGRect() }
      .shareReplay(1)

    let timer = Observable.combineLatest(dateDifference, chartWidth) { ($0, $1) }
      .map { dateComponents, chartBounds in
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: dateComponents, to: endDate) ?? endDate
        let timeRange = endDate.timeIntervalSince(startDate)
        let interval = ceil(timeRange / Double(chartBounds.width))
        return (startDate, endDate, interval)
      }
      .flatMapLatest { limitData -> Observable<ChartLimitData> in
        Observable.interval(limitData.2, scheduler: MainScheduler.instance)
          .startWith(0)
          .map { _ in limitData }
      }

    let visible = self.visible.asObservable()

    Observable.combineLatest(timer, visible) { ($0, $1) }
      .filter { $0.1 == true }
      .map { $0.0 }
      .flatMapLatest { [weak self] (startDate, endDate, interval) -> Observable<[DataPoint]> in
        guard let strongSelf = self else { return Observable.empty() }
        return strongSelf.viewModel.fetchData(at: startDate, until: endDate, interval: Int(interval))
      }
      .observeOn(MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] dataPoints in
          guard let strongSelf = self else { return }

          guard let data = strongSelf.chartView.data,
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
          strongSelf.chartView.notifyDataSetChanged()
        },
        onError: { (error) in
          // TODO
      })
      .addDisposableTo(self.disposeBag)
  }

}
