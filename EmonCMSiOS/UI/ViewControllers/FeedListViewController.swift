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

  @IBOutlet private var tableView: UITableView!
  @IBOutlet private var refreshButton: UIBarButtonItem!
  @IBOutlet private var lastUpdatedLabel: UILabel!

  private let searchController = UISearchController(searchResultsController: nil)
  private let searchSubject = CurrentValueSubject<String, Never>("")

  private var dataSource: CombineTableViewDataSource<FeedListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()

  private var emptyLabel: UILabel?
  private var selectedIndex: IndexPath? {
    didSet {
      var indicesToReload: [IndexPath] = []
      if let oldValue = oldValue {
        indicesToReload.append(oldValue)
      }
      if let newValue = self.selectedIndex {
        indicesToReload.append(newValue)
      }
      self.tableView.beginUpdates()
      self.tableView.reloadRows(at: indicesToReload, with: .automatic)
      self.tableView.endUpdates()
    }
  }

  private enum Segues: String {
    case showFeed
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

    self.searchController.delegate = self
    self.searchController.searchResultsUpdater = self
    self.searchController.obscuresBackgroundDuringPresentation = false
    self.searchController.searchBar.placeholder = "Search feeds"
    self.navigationItem.searchController = self.searchController
    self.definesPresentationContext = true

    self.setupDataSource()
    self.setupBindings()
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
    self.tableView.register(UINib(nibName: "FeedCell", bundle: nil), forCellReuseIdentifier: "FeedCell")

    let dataSource = CombineTableViewDataSource<FeedListViewModel.Section>(
      configureCell: { _, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedCell
        cell.titleLabel.text = item.name
        cell.valueLabel.text = item.value

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

        let selected = self.selectedIndex == indexPath
        if selected {
          let chartViewModel = self.viewModel.feedChartViewModel(forFeedId: item.feedId)
          cell.chartViewModel.send(chartViewModel)
        } else {
          cell.chartViewModel.send(nil)
        }

        cell.disclosureButton
          .publisher(for: .touchUpInside)
          .prefix(untilOutputFrom: cell.prepareForReuseSignal)
          .sink { [weak self] _ in
            guard let self = self else { return }
            self.showFeed(atIndexPath: indexPath)
          }
          .store(in: &self.cancellables)

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
      .sink { [weak self] indexPath in
        guard let self = self else { return }

        self.searchController.searchBar.resignFirstResponder()

        if self.selectedIndex == indexPath {
          self.selectedIndex = nil
        } else {
          self.selectedIndex = indexPath
        }
      }
      .store(in: &self.cancellables)
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

  private func showFeed(atIndexPath indexPath: IndexPath) {
    let item = self.dataSource.model(at: indexPath)
    self.showFeed(withId: item.feedId)
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

extension FeedListViewController: UISearchControllerDelegate {
  public func willPresentSearchController(_ searchController: UISearchController) {
    self.selectedIndex = nil
  }

  public func willDismissSearchController(_ searchController: UISearchController) {
    self.selectedIndex = nil
  }
}

extension FeedListViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    self.searchSubject.send(searchController.searchBar.text ?? "")
  }
}
