//
//  AppListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

final class AppListViewController: UITableViewController {

  var viewModel: AppListViewModel!

  private var emptyLabel: UILabel?

  fileprivate let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Apps"

    self.setupDataSource()
    self.setupBindings()
    self.setupNavigation()
  }

  private func setupDataSource() {
    let dataSource = RxTableViewSectionedReloadDataSource<AppListViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.name
        return cell
    },
      titleForHeaderInSection: { _,_  in "" },
      canEditRowAtIndexPath: { _,_  in true },
      canMoveRowAtIndexPath: { _,_  in false })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.apps
      .map { [AppListViewModel.Section(model: "", items: $0)] }
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)
  }

  private func setupBindings() {
    self.tableView.rx
      .modelSelected(AppListViewModel.ListItem.self)
      .subscribe(onNext: { [unowned self] in
        self.presentApp(withId: $0.appId, ofCategory: $0.category)
      })
      .disposed(by: self.disposeBag)

    self.tableView.rx
      .itemDeleted
      .map { [unowned self] in
        let item: AppListViewModel.ListItem = try! self.tableView.rx.model(at: $0)
        return item.appId
      }
      .flatMap { [unowned self] in
        self.viewModel.deleteApp(withId: $0)
          .catchErrorJustReturn(())
      }
      .subscribe()
      .disposed(by: self.disposeBag)

    self.viewModel.apps
      .map {
        $0.count == 0
      }
      .drive(onNext: { [weak self] empty in
        guard let strongSelf = self else { return }

        if empty {
          let emptyLabel = UILabel(frame: CGRect.zero)
          emptyLabel.translatesAutoresizingMaskIntoConstraints = false
          emptyLabel.text = "Tap + to add a new app"
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
    self.navigationItem.leftBarButtonItem = self.editButtonItem

    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    rightBarButtonItem.rx.tap
      .flatMapLatest { [weak self] () -> Observable<AppCategory> in
        guard let strongSelf = self else { return Observable.empty() }

        return Observable.create { observer in
          let alert = UIAlertController(title: "Select a type", message: nil, preferredStyle: .actionSheet)

          alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            observer.on(.completed)
          })

          AppCategory.allCases.forEach { appCategory in
            alert.addAction(UIAlertAction(title: appCategory.info.displayName, style: .default) { _ in
              observer.on(.next(appCategory))
              observer.on(.completed)
            })
          }

          strongSelf.present(alert, animated: true, completion: nil)

          return Disposables.create {
            alert.dismiss(animated: true, completion: nil)
          }
        }
      }
      .flatMapLatest { [weak self] (appCategory) -> Driver<AppUUIDAndCategory?> in
        guard let strongSelf = self else { return Driver.empty() }

        let viewModel = self?.viewModel.appConfigViewModel(forCategory: appCategory)
        let viewController = AppConfigViewController()
        viewController.viewModel = viewModel
        let navController = UINavigationController(rootViewController: viewController)

        strongSelf.present(navController, animated: true, completion: nil)

        return viewController.finished
      }
      .subscribe(onNext: { [weak self] appUUIDAndCategory in
        guard let strongSelf = self else { return }
        strongSelf.dismiss(animated: true) {
          if let appUUIDAndCategory = appUUIDAndCategory {
            strongSelf.presentApp(withId: appUUIDAndCategory.uuid, ofCategory: appUUIDAndCategory.category)
          }
        }
      })
      .disposed(by: self.disposeBag)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

  private func presentApp(withId appId: String, ofCategory category: AppCategory) {
    let viewController = self.viewModel.viewController(forDataWithId: appId, ofCategory: category)
    self.navigationController?.pushViewController(viewController, animated: true)
  }

}
