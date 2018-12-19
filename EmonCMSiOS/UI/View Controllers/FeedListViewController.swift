//
//  ViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 11/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources
import Charts

final class FeedListViewController: UIViewController {

  var viewModel: FeedListViewModel!
  let chartViewModel = BehaviorRelay<FeedChartViewModel?>(value: nil)

  @IBOutlet fileprivate var tableView: UITableView!
  @IBOutlet fileprivate var refreshButton: UIBarButtonItem!
  @IBOutlet fileprivate var chartContainerView: UIView!
  @IBOutlet fileprivate var chartContainerViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet fileprivate var chartView: LineChartView!
  @IBOutlet fileprivate var chartSpinner: UIActivityIndicatorView!
  @IBOutlet fileprivate var chartLabelContainerView: UIView!
  @IBOutlet fileprivate var chartControlsContainerView: UIView!
  @IBOutlet fileprivate var chartSegmentedControl: UISegmentedControl!

  fileprivate let disposeBag = DisposeBag()

  fileprivate enum Segues: String {
    case showFeed
  }

  fileprivate var chartContainerMinDisplacement: CGFloat {
    return self.chartControlsContainerView.frame.maxY
  }

  fileprivate var chartContainerMaxDisplacement: CGFloat {
    return self.chartView.frame.maxY + 8
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Feeds"

    self.tableView.estimatedRowHeight = 68.0
    self.tableView.rowHeight = UITableView.automaticDimension
    self.tableView.refreshControl = UIRefreshControl()

    self.chartContainerView.layer.cornerRadius = 20.0
    self.chartContainerView.clipsToBounds = true
    self.chartContainerView.layer.borderColor = UIColor(white: 0.7, alpha: 1.0).cgColor
    self.chartContainerView.layer.borderWidth = 2.0

    self.setupDataSource()
    self.setupDragRecogniser()
    self.setupChartView()
    self.setupBindings()
    self.setupChartBindings()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let insetBottom = self.chartContainerViewBottomConstraint.constant

    var contentInset = self.tableView.contentInset
    contentInset.bottom = insetBottom
    self.tableView.contentInset = contentInset

    var scrollIndicatorInsets = self.tableView.scrollIndicatorInsets
    scrollIndicatorInsets.bottom = insetBottom
    self.tableView.scrollIndicatorInsets = scrollIndicatorInsets
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.active.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active.accept(false)
  }

  private func setupDataSource() {
    self.tableView.register(UINib(nibName: "ValueCell", bundle: nil), forCellReuseIdentifier: "ValueCell")

    let dataSource = RxTableViewSectionedReloadDataSource<FeedListViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "ValueCell", for: indexPath) as! ValueCell
        cell.titleLabel.text = item.name
        cell.valueLabel.text = item.value
        cell.accessoryType = .detailDisclosureButton

        let secondsAgo = Int(floor(max(-item.time.timeIntervalSinceNow, 0)))
        let value: String
        let colour: UIColor
        if secondsAgo < 60 {
          value = "\(secondsAgo) secs"
          colour = EmonCMSColors.ActivityIndicator.Green
        } else if secondsAgo < 3600 {
          value = "\(secondsAgo / 60) mins"
          colour = EmonCMSColors.ActivityIndicator.Yellow
        } else if secondsAgo < 86400 {
          value = "\(secondsAgo / 3600) hours"
          colour = EmonCMSColors.ActivityIndicator.Orange
        } else {
          value = "\(secondsAgo / 86400) days"
          colour = EmonCMSColors.ActivityIndicator.Red
        }
        cell.timeLabel.text = value
        cell.activityCircle.backgroundColor = colour

        return cell
    },
      titleForHeaderInSection: { (ds, index) in
        return ds.sectionModels[index].model
    })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.feeds
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)

    self.tableView.rx.itemSelected
      .map { [weak self] indexPath -> FeedChartViewModel? in
        guard let strongSelf = self else { return nil }

        let item = try! dataSource.model(at: indexPath) as! FeedListViewModel.ListItem
        let chartViewModel = strongSelf.viewModel.feedChartViewModel(forItem: item)
        return chartViewModel
      }
      .bind(to: self.chartViewModel)
      .disposed(by: self.disposeBag)

    self.tableView.rx.itemAccessoryButtonTapped
      .subscribe(onNext: { [weak self] indexPath in
        guard let strongSelf = self else { return }
        let item = try! dataSource.model(at: indexPath)
        strongSelf.performSegue(withIdentifier: Segues.showFeed.rawValue, sender: item)
      })
      .disposed(by: self.disposeBag)
  }

  private func setupDragRecogniser() {
    let gestureRecogniser = UIPanGestureRecognizer()
    self.chartContainerView.addGestureRecognizer(gestureRecogniser)

    var beginConstant = CGFloat(0)

    let dragProgress = gestureRecogniser.rx.event
      .map { [weak self] recognizer -> (CGFloat, CGFloat, Bool) in
        guard let self = self else { return (0, 0, false) }

        if recognizer.state == .began {
          beginConstant = self.chartContainerViewBottomConstraint.constant
        }

        let minY = self.chartContainerMinDisplacement
        let maxY = self.chartContainerMaxDisplacement

        let translation = recognizer.translation(in: self.view).y
        let velocity = recognizer.velocity(in: self.view).y
        var newConstantValue = beginConstant - translation

        if newConstantValue < minY {
          newConstantValue = minY
        } else if newConstantValue > maxY {
          // Rubber banding equation from: https://twitter.com/chpwn/status/285540192096497664
          newConstantValue = maxY + (1.0 - (1.0 / (((newConstantValue - maxY) * 0.55 / maxY) + 1.0))) * maxY
        }

        let progress = (newConstantValue - minY) / (maxY - minY)

        switch recognizer.state {
        case .ended, .failed, .cancelled:
          let endProgress = (progress > 0.5) ? CGFloat(1.0) : CGFloat(0.0)
          return (endProgress, velocity, true)
        case .began, .changed, .possible:
          return (progress, velocity, false)
        }
      }

    let tapRecogniser = UITapGestureRecognizer()
    self.chartLabelContainerView.addGestureRecognizer(tapRecogniser)

    let tapProgress = Observable.merge(
      tapRecogniser.rx.event.becomeVoid(),
      self.tableView.rx.itemSelected.becomeVoid()
      )
      .map { _ in (CGFloat(1), CGFloat(0), true) }

    Observable.merge(dragProgress, tapProgress)
      .asDriver(onErrorJustReturn: (0, 0, false))
      .drive(onNext: { [weak self] (progress, velocity, animated) in
        guard let self = self else { return }

        let displacement = self.chartContainerMinDisplacement + (progress * (self.chartContainerMaxDisplacement - self.chartContainerMinDisplacement))

        self.chartContainerViewBottomConstraint.constant = displacement
        UIView.animate(withDuration: animated ? 0.3 : 0.0,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: -(velocity / self.chartContainerMaxDisplacement),
                       options: UIView.AnimationOptions(rawValue: 0),
                       animations: {
                        self.chartControlsContainerView.alpha = progress
                        self.chartLabelContainerView.alpha = 1.0 - progress
                        self.view.layoutIfNeeded()
        }, completion: nil)
      })
      .disposed(by: self.disposeBag)
  }

  private func setupChartView() {
    let chartView = self.chartView!

    chartView.dragEnabled = false
    chartView.pinchZoomEnabled = false
    chartView.highlightPerTapEnabled = false
    chartView.setScaleEnabled(false)
    chartView.chartDescription = nil
    chartView.drawGridBackgroundEnabled = false
    chartView.legend.enabled = false
    chartView.rightAxis.enabled = false

    let xAxis = chartView.xAxis
    xAxis.drawGridLinesEnabled = false
    xAxis.labelPosition = .bottom
    xAxis.valueFormatter = ChartDateValueFormatter(.auto)

    let yAxis = chartView.leftAxis
    yAxis.drawGridLinesEnabled = false
    yAxis.labelPosition = .outsideChart
    yAxis.drawZeroLineEnabled = true
  }

  private func setupBindings() {
    let refreshControl = self.tableView.refreshControl!

    Observable.of(self.refreshButton.rx.tap, refreshControl.rx.controlEvent(.valueChanged))
      .merge()
      .bind(to: self.viewModel.refresh)
      .disposed(by: self.disposeBag)

    self.viewModel.isRefreshing
      .drive(refreshControl.rx.isRefreshing)
      .disposed(by: self.disposeBag)

    self.viewModel.isRefreshing
      .map { !$0 }
      .drive(self.refreshButton.rx.isEnabled)
      .disposed(by: self.disposeBag)
  }

  private func setupChartBindings() {

    self.chartViewModel
      .asObservable()
      .flatMapLatest { chartViewModel -> Observable<Bool> in
        if let chartViewModel = chartViewModel {
          return chartViewModel.isRefreshing.throttle(0.3).asObservable()
        } else {
          return Observable<Bool>.never()
        }
      }
      .asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] refreshing in
        guard let self = self else { return }

        if refreshing {
          self.chartSpinner.startAnimating()
          self.chartView.alpha = 0.5
        } else {
          self.chartSpinner.stopAnimating()
          self.chartView.alpha = 1.0
        }
      })
      .disposed(by: self.disposeBag)

    self.chartViewModel
      .asDriver()
      .drive(onNext: { [weak self] chartViewModel in
        guard let self = self else { return }

        if chartViewModel == nil {
          self.chartView.noDataText = "Select a feed"
        } else {
          self.chartView.noDataText = "No data"
        }
      })
      .disposed(by: self.disposeBag)

    self.chartViewModel
      .asObservable()
      .flatMapLatest { [weak self] chartViewModel -> Observable<()> in
        let disposeBag = CompositeDisposable()

        if let self = self, let chartViewModel = chartViewModel {
          let disposable1 = self.chartSegmentedControl.rx.selectedSegmentIndex
            .startWith(self.chartSegmentedControl.selectedSegmentIndex)
            .map {
              DateRange.relative(DateRange.RelativeTime(rawValue: $0) ?? .hour1)
            }
            .bind(to: chartViewModel.dateRange)
          _ = disposeBag.insert(disposable1)

          let disposable2 = chartViewModel.dataPoints
            .drive(onNext: { [weak self] dataPoints in
              guard let strongSelf = self else { return }

              let chartView = strongSelf.chartView!

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
          chartViewModel.active.accept(true)
          _ = disposeBag.insert(disposable2)
        }

        return Observable<()>.never()
          .do(onDispose: {
            disposeBag.dispose()
          })
      }
      .subscribe()
      .disposed(by: self.disposeBag)
  }

}

extension FeedListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showFeed.rawValue {
      let feedViewController = segue.destination as! FeedChartViewController
      let item = sender as! FeedListViewModel.ListItem
      let viewModel = self.viewModel.feedChartViewModel(forItem: item)
      feedViewController.viewModel = viewModel
    }
  }

}
