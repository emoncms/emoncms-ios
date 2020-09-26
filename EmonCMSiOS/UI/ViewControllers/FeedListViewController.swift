//
//  FeedListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 11/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

import Charts

final class FeedListViewController: UIViewController {
  var viewModel: FeedListViewModel!
  let chartViewModel = CurrentValueSubject<FeedChartViewModel?, Never>(nil)

  @IBOutlet private var tableView: UITableView!
  @IBOutlet private var refreshButton: UIBarButtonItem!
  @IBOutlet private var lastUpdatedLabel: UILabel!
  @IBOutlet private var chartContainerView: UIView!
  @IBOutlet private var chartContainerViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet private var chartView: LineChartView!
  @IBOutlet private var chartSpinner: UIActivityIndicatorView!
  @IBOutlet private var chartLabelContainerView: UIView!
  @IBOutlet private var chartControlsContainerView: UIView!
  @IBOutlet private var chartSegmentedControl: UISegmentedControl!

  private let searchController = UISearchController(searchResultsController: nil)
  private let searchSubject = CurrentValueSubject<String, Never>("")

  private var dataSource: CombineTableViewDataSource<FeedListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()

  private var emptyLabel: UILabel?

  private enum Segues: String {
    case showFeed
  }

  fileprivate var chartContainerMinDisplacement: CGFloat {
    return self.chartControlsContainerView.frame.maxY
  }

  fileprivate var chartContainerMaxDisplacement: CGFloat {
    return self.chartView.frame.maxY + 8
  }

  func showFeed(withId id: String, animated: Bool = true) {
    self.performSegue(withIdentifier: Segues.showFeed.rawValue, sender: id)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Feeds"
    self.tableView.accessibilityIdentifier = AccessibilityIdentifiers.Lists.Feed

    self.tableView.estimatedRowHeight = 68.0
    self.tableView.rowHeight = UITableView.automaticDimension
    self.tableView.refreshControl = UIRefreshControl()

    self.searchController.searchResultsUpdater = self
    self.searchController.obscuresBackgroundDuringPresentation = false
    self.searchController.searchBar.placeholder = "Search feeds"
    self.navigationItem.searchController = self.searchController
    self.definesPresentationContext = true

    self.chartContainerView.accessibilityIdentifier = AccessibilityIdentifiers.FeedList.ChartContainer
    self.chartContainerView.layer.cornerRadius = 20.0
    self.chartContainerView.clipsToBounds = true
    self.chartContainerView.layer.borderWidth = 1.0

    self.chartContainerViewBottomConstraint.constant = self.chartContainerMinDisplacement

    self.setupDataSource()
    self.setupDragRecogniser()
    self.setupChartView()
    self.setupBindings()
    self.setupChartBindings()
    self.updateForCurrentTraitCollection()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    self.updateForCurrentTraitCollection()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let insetBottom = self.chartContainerViewBottomConstraint.constant

    var contentInset = self.tableView.contentInset
    contentInset.bottom = insetBottom
    self.tableView.contentInset = contentInset

    var scrollIndicatorInsets = self.tableView.verticalScrollIndicatorInsets
    scrollIndicatorInsets.bottom = insetBottom
    self.tableView.verticalScrollIndicatorInsets = scrollIndicatorInsets
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Annoyingly this has to be in DIDappear and not WILLappear, otherwise it causes a weird
    // navigation bar bug when going back to the feed list view from a feed detail view.
    self.viewModel.active = true
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active = false
  }

  private func setupDataSource() {
    self.tableView.register(UINib(nibName: "ValueCell", bundle: nil), forCellReuseIdentifier: "ValueCell")

    let dataSource = CombineTableViewDataSource<FeedListViewModel.Section>(
      configureCell: { _, tableView, indexPath, item in
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
      titleForHeaderInSection: { ds, index in
        ds.sectionModels[index].model
      })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$feeds
      .eraseToAnyPublisher()

    dataSource.assign(toTableView: self.tableView, items: items)
    self.dataSource = dataSource

    self.dataSource
      .itemSelected
      .map { [weak self] indexPath -> FeedChartViewModel? in
        guard let self = self else { return nil }

        self.searchController.searchBar.resignFirstResponder()

        let item = self.dataSource.model(at: indexPath)
        let chartViewModel = self.viewModel.feedChartViewModel(forFeedId: item.feedId)
        return chartViewModel
      }
      .subscribe(self.chartViewModel)
      .store(in: &self.cancellables)

    self.dataSource
      .itemAccessoryButtonTapped
      .sink { [weak self] indexPath in
        guard let self = self else { return }
        let item = dataSource.model(at: indexPath)
        self.showFeed(withId: item.feedId)
      }
      .store(in: &self.cancellables)
  }

  private func setupDragRecogniser() {
    let gestureRecogniser = UIPanGestureRecognizer()
    self.chartContainerView.addGestureRecognizer(gestureRecogniser)

    var beginConstant = CGFloat(0)

    let dragProgress = gestureRecogniser.publisher()
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
        @unknown default:
          return (progress, velocity, false)
        }
      }

    let tapRecogniser = UITapGestureRecognizer()
    self.chartLabelContainerView.addGestureRecognizer(tapRecogniser)

    let tapProgress = Publishers.Merge(
      tapRecogniser.publisher().becomeVoid(),
      self.dataSource.itemSelected.becomeVoid())
      .map { _ in (CGFloat(1), CGFloat(0), true) }

    Publishers.Merge(dragProgress, tapProgress)
      .sink { [weak self] progress, velocity, animated in
        guard let self = self else { return }

        let displacement = self
          .chartContainerMinDisplacement +
          (progress * (self.chartContainerMaxDisplacement - self.chartContainerMinDisplacement))

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
                       },
                       completion: nil)
      }
      .store(in: &self.cancellables)
  }

  private func setupChartView() {
    let chartView = self.chartView!
    ChartHelpers.setupDefaultLineChart(chartView)
  }

  private func setupBindings() {
    let refreshControl = self.tableView.refreshControl!
    let appBecameActive = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
      .becomeVoid()
    Publishers.Merge3(self.refreshButton.publisher().becomeVoid(),
                      refreshControl.publisher(for: .valueChanged).becomeVoid(),
                      appBecameActive)
      .subscribe(self.viewModel.refresh)
      .store(in: &self.cancellables)

    let dateFormatter = DateFormatter()
    self.viewModel.$updateTime
      .map { time in
        var string = "Last updated: "
        if let time = time {
          if time.timeIntervalSinceNow < -86400 {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
          } else {
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .medium
          }
          string += dateFormatter.string(from: time)
        } else {
          string += "Never"
        }
        return string
      }
      .assign(to: \.text, on: self.lastUpdatedLabel)
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
      .map { !$0 }
      .assign(to: \.isEnabled, on: self.refreshButton)
      .store(in: &self.cancellables)

    self.searchSubject
      .assign(to: \.searchTerm, on: self.viewModel)
      .store(in: &self.cancellables)

    self.viewModel.$feeds
      .map {
        $0.count == 0
      }
      .removeDuplicates()
      .sink { [weak self] empty in
        guard let self = self else { return }

        self.tableView.tableHeaderView?.isHidden = empty

        if empty {
          let emptyLabel = UILabel(frame: CGRect.zero)
          emptyLabel.translatesAutoresizingMaskIntoConstraints = false
          emptyLabel.text = "No feeds"
          emptyLabel.numberOfLines = 0
          emptyLabel.textColor = .systemGray3
          self.emptyLabel = emptyLabel

          let tableView = self.tableView!
          tableView.addSubview(emptyLabel)
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: tableView,
            attribute: .centerX,
            multiplier: 1,
            constant: 0))
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .leading,
            relatedBy: .greaterThanOrEqual,
            toItem: tableView,
            attribute: .leading,
            multiplier: 1,
            constant: 8))
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .trailing,
            relatedBy: .lessThanOrEqual,
            toItem: tableView,
            attribute: .trailing,
            multiplier: 1,
            constant: 8))
          tableView.addConstraint(NSLayoutConstraint(
            item: emptyLabel,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: tableView,
            attribute: .top,
            multiplier: 1,
            constant: 44.0 * 1.5))
        } else {
          if let emptyLabel = self.emptyLabel {
            emptyLabel.removeFromSuperview()
          }
        }
      }
      .store(in: &self.cancellables)
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
      .sink { [weak self] chartViewModel in
        guard let self = self else { return }

        if chartViewModel == nil {
          self.chartView.noDataText = "Select a feed"
        } else {
          self.chartView.noDataText = "No data"
        }
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

  private func updateForCurrentTraitCollection() {
    switch self.traitCollection.userInterfaceStyle {
    case .light, .unspecified:
      self.chartContainerView.layer.borderColor = UIColor(white: 0.7, alpha: 1.0).cgColor
    case .dark:
      self.chartContainerView.layer.borderColor = UIColor(white: 0.2, alpha: 1.0).cgColor
    @unknown default:
      self.chartContainerView.layer.borderColor = UIColor(white: 0.7, alpha: 1.0).cgColor
    }
  }
}

extension FeedListViewController {
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.showFeed.rawValue {
      let feedViewController = segue.destination as! FeedChartViewController
      let feedId = sender as! String
      let viewModel = self.viewModel.feedChartViewModel(forFeedId: feedId)
      feedViewController.viewModel = viewModel
    }
  }
}

extension FeedListViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    self.searchSubject.send(searchController.searchBar.text ?? "")
  }
}
