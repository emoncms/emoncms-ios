//
//  DashboardListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import SafariServices
import UIKit

final class DashboardListViewController: UITableViewController {
  var viewModel: DashboardListViewModel!

  private var emptyLabel: UILabel?
  @IBOutlet private var refreshButton: UIBarButtonItem!
  @IBOutlet private var lastUpdatedLabel: UILabel!

  private var dataSource: CombineTableViewDataSource<DashboardListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Dashboards"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Lists.Dashboard

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
    let dataSource = CombineTableViewDataSource<DashboardListViewModel.Section>(
      configureCell: { _, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = item.desc
        return cell
      },
      titleForHeaderInSection: { _, _ in "" },
      canEditRowAtIndexPath: { _, _ in true },
      canMoveRowAtIndexPath: { _, _ in false })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$dashboards
      .map { [DashboardListViewModel.Section(model: "", items: $0)] }
      .eraseToAnyPublisher()

    dataSource.assign(toTableView: self.tableView, items: items)
    self.dataSource = dataSource
  }

  private func setupBindings() {
    let refreshControl = self.refreshControl!
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

    self.dataSource
      .modelSelected
      .sink { [weak self] in
        guard let self = self else { return }
        self.openDashboard(withId: $0.dashboardId)
      }
      .store(in: &self.cancellables)

    Publishers.CombineLatest(
      self.viewModel.$serverNeedsUpdate
        .removeDuplicates(),
      self.viewModel.$dashboards
        .map { $0.isEmpty }
        .removeDuplicates())
            .sink { [weak self] serverNeedsUpdate, dashboardsEmpty in
              guard let self = self else { return }

              let showLabel = serverNeedsUpdate || dashboardsEmpty

              self.tableView.tableHeaderView?.isHidden = showLabel

              if showLabel {
                let emptyLabel = self.emptyLabel ?? UILabel(frame: CGRect.zero)
                self.emptyLabel = emptyLabel
                emptyLabel.translatesAutoresizingMaskIntoConstraints = false
                emptyLabel.numberOfLines = 0
                emptyLabel.textColor = .lightGray
                emptyLabel.textAlignment = .center

                if serverNeedsUpdate {
                  emptyLabel
                    .text =
                    "Cannot fetch dashboards.\n\nYou may need to upgrade Emoncms to be able to fetch dashboards. Please check that your Emoncms is up-to-date and then try again."
                } else {
                  emptyLabel.text = "No dashboards"
                }

                self.view.addSubview(emptyLabel)
                self.view.addConstraint(NSLayoutConstraint(
                  item: emptyLabel,
                  attribute: .centerX,
                  relatedBy: .equal,
                  toItem: self.view,
                  attribute: .centerX,
                  multiplier: 1,
                  constant: 0))
                self.view.addConstraint(NSLayoutConstraint(
                  item: emptyLabel,
                  attribute: .leading,
                  relatedBy: .greaterThanOrEqual,
                  toItem: self.view,
                  attribute: .leading,
                  multiplier: 1,
                  constant: 8))
                self.view.addConstraint(NSLayoutConstraint(
                  item: emptyLabel,
                  attribute: .trailing,
                  relatedBy: .lessThanOrEqual,
                  toItem: self.view,
                  attribute: .trailing,
                  multiplier: 1,
                  constant: 8))
                self.view.addConstraint(NSLayoutConstraint(
                  item: emptyLabel,
                  attribute: .centerY,
                  relatedBy: .equal,
                  toItem: self.view,
                  attribute: .top,
                  multiplier: 1,
                  constant: 44.0 * 1.5))
                self.view.layoutIfNeeded()
              } else {
                if let emptyLabel = self.emptyLabel {
                  emptyLabel.removeFromSuperview()
                }
              }
            }
            .store(in: &self.cancellables)
  }

  private func openDashboard(withId dashboardId: String) {
    guard let url = self.viewModel.urlForDashboard(withId: dashboardId) else {
      AppLog.error("Failed to create URL for dashboard with id: \(dashboardId)")
      return
    }

    let viewController = SFSafariViewController(url: url)
    viewController.dismissButtonStyle = .close
    self.present(viewController, animated: true, completion: nil)
  }
}
