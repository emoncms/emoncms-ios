//
//  InputListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

final class InputListViewController: UITableViewController {
  var viewModel: InputListViewModel!

  private var dataSource: CombineTableViewDataSource<InputListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()

  @IBOutlet private var refreshButton: UIBarButtonItem!
  @IBOutlet private var lastUpdatedLabel: UILabel!
  private var emptyLabel: UILabel?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Inputs"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Lists.Input

    self.tableView.estimatedRowHeight = 68.0
    self.tableView.rowHeight = UITableView.automaticDimension
    self.tableView.allowsSelection = false

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
    self.tableView.register(UINib(nibName: "InputCell", bundle: nil), forCellReuseIdentifier: "InputCell")

    let dataSource = CombineTableViewDataSource<InputListViewModel.Section>(
      configureCell: { _, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell", for: indexPath) as! InputCell
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

        return cell
      },
      titleForHeaderInSection: { ds, index in
        ds.sectionModels[index].model
      })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$inputs
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

    Publishers.CombineLatest(
      self.viewModel.$serverNeedsUpdate
        .removeDuplicates(),
      self.viewModel.$inputs
        .map { $0.isEmpty }
        .removeDuplicates())
      .sink { [weak self] serverNeedsUpdate, inputsEmpty in
        guard let self = self else { return }

        let showLabel = serverNeedsUpdate || inputsEmpty

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
              "Cannot fetch inputs.\n\nYou may need to upgrade Emoncms to be able to fetch inputs. Please check that your Emoncms is up-to-date and then try again."
          } else {
            emptyLabel.text = "No inputs"
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
}
