//
//  InputListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

final class InputListViewController: UITableViewController {

  var viewModel: InputListViewModel!

  private let disposeBag = DisposeBag()

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
    self.viewModel.active.accept(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.viewModel.active.accept(false)
  }

  private func setupDataSource() {
    self.tableView.register(UINib(nibName: "ValueCell", bundle: nil), forCellReuseIdentifier: "ValueCell")

    let dataSource = RxTableViewSectionedReloadDataSource<InputListViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "ValueCell", for: indexPath) as! ValueCell
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
      titleForHeaderInSection: { (ds, index) in
        return ds.sectionModels[index].model
    })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.inputs
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)
  }

  private func setupBindings() {
    let refreshControl = self.refreshControl!

    Observable.of(self.refreshButton.rx.tap, refreshControl.rx.controlEvent(.valueChanged))
      .merge()
      .bind(to: self.viewModel.refresh)
      .disposed(by: self.disposeBag)

    let dateFormatter = DateFormatter()
    self.viewModel.updateTime
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
      .drive(self.lastUpdatedLabel.rx.text)
      .disposed(by: self.disposeBag)

    self.viewModel.isRefreshing
      .drive(refreshControl.rx.isRefreshing)
      .disposed(by: self.disposeBag)

    Driver.combineLatest(self.viewModel.inputs, self.viewModel.isRefreshing)
      .map { inputs, isRefreshing in
        inputs.count == 0 && !isRefreshing
      }
      .drive(onNext: { [weak self] empty in
        guard let self = self else { return }

        self.tableView.tableHeaderView?.isHidden = empty

        if empty {
          let emptyLabel = UILabel(frame: CGRect.zero)
          emptyLabel.translatesAutoresizingMaskIntoConstraints = false
          emptyLabel.text = "Cannot fetch inputs.\n\nYou may need to upgrade Emoncms to be able to fetch inputs. Please check that your Emoncms is up-to-date and then try again."
          emptyLabel.numberOfLines = 0
          emptyLabel.textColor = .lightGray
          emptyLabel.textAlignment = .center
          self.emptyLabel = emptyLabel

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
        } else {
          if let emptyLabel = self.emptyLabel {
            emptyLabel.removeFromSuperview()
          }
        }
      })
      .disposed(by: self.disposeBag)
  }

}
