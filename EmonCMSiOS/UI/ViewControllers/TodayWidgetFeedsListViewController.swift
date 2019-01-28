//
//  TodayWidgetFeedsListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

final class TodayWidgetFeedsListViewController: UITableViewController {

  var viewModel: TodayWidgetFeedsListViewModel!

  private var emptyLabel: UILabel?

  private let disposeBag = DisposeBag()
  private var firstLoad = true

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Today Widget Feeds"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Lists.TodayWidgetFeed
    self.navigationItem.largeTitleDisplayMode = .never

    self.tableView.allowsSelection = false

    self.setupDataSource()
    self.setupBindings()
    self.setupNavigation()
  }

  private func setupDataSource() {
    let dataSource = RxTableViewSectionedReloadDataSource<TodayWidgetFeedsListViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ??
          UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = item.feedName
        cell.detailTextLabel?.text = item.accountName
        return cell
    },
      titleForHeaderInSection: { _,_ in "" },
      canEditRowAtIndexPath: { _,_  in true },
      canMoveRowAtIndexPath: { _,_  in true })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.feeds
      .map { [TodayWidgetFeedsListViewModel.Section(model: "", items: $0)] }
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)
  }

  private func setupBindings() {
    self.tableView.rx
      .itemDeleted
      .map { [unowned self] in
        let item: TodayWidgetFeedsListViewModel.ListItem = try! self.tableView.rx.model(at: $0)
        return item.todayWidgetFeedId
      }
      .flatMap { [unowned self] in
        self.viewModel.deleteTodayWidgetFeed(withId: $0)
          .catchErrorJustReturn(())
      }
      .subscribe()
      .disposed(by: self.disposeBag)

    self.tableView.rx
      .itemMoved
      .flatMap { [weak self] event -> Observable<()> in
        guard let self = self else { return Observable.empty() }
        return self.viewModel.moveTodayWidgetFeed(fromIndex: event.sourceIndex.row, toIndex: event.destinationIndex.row)
          .catchErrorJustReturn(())
      }
      .subscribe()
      .disposed(by: self.disposeBag)

    self.viewModel.feeds
      .map {
        $0.count == 0
      }
      .drive(onNext: { [weak self] empty in
        guard let strongSelf = self else { return }

        if empty {
          let emptyLabel = UILabel(frame: CGRect.zero)
          emptyLabel.translatesAutoresizingMaskIntoConstraints = false
          emptyLabel.text = "Tap + to add a new feed"
          emptyLabel.numberOfLines = 0
          emptyLabel.textColor = .lightGray
          strongSelf.emptyLabel = emptyLabel

          let tableView = strongSelf.tableView!
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
          if let emptyLabel = strongSelf.emptyLabel {
            emptyLabel.removeFromSuperview()
          }
        }
      })
      .disposed(by: self.disposeBag)
  }

  private func setupNavigation() {
    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    rightBarButtonItem.rx.tap
      .flatMapLatest { [weak self] _ -> Observable<Bool> in
        guard let self = self else { return Observable.just(false) }

        let viewController = AppSelectFeedViewController()
        viewController.viewModel = self.viewModel.feedListViewModel()
        self.navigationController?.pushViewController(viewController, animated: true)

        return viewController.finished
          .asObservable()
          .flatMap { [weak self] feedId -> Observable<Bool> in
            guard let self = self else { return Observable.just(false) }
            guard let feedId = feedId else { return Observable.just(false) }
            return self.viewModel.addTodayWidgetFeed(forFeedId: feedId)
          }
      }
      .subscribe(onNext: { [weak self] _ in
        guard let self = self else { return }
        self.navigationController?.popViewController(animated: true)
      })
      .disposed(by: self.disposeBag)
    self.navigationItem.rightBarButtonItems = [self.editButtonItem, rightBarButtonItem]
  }

}
