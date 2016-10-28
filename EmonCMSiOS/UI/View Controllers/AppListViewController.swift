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

  fileprivate let dataSource = RxTableViewSectionedReloadDataSource<AppListViewModel.Section>()
  fileprivate let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Apps"

    self.setupDataSource()
    self.setupBindings()
    self.setupNavigation()
  }

  private func setupDataSource() {
    self.dataSource.configureCell = { (ds, tableView, indexPath, item) in
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
      cell.textLabel?.text = item.name
      return cell
    }

    self.dataSource.titleForHeaderInSection = { _ in "" }

    self.dataSource.canEditRowAtIndexPath = { _ in true }

    self.dataSource.canMoveRowAtIndexPath = { _ in false }

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.apps
      .map { [AppListViewModel.Section(model: "", items: $0)] }
      .drive(self.tableView.rx.items(dataSource: self.dataSource))
      .addDisposableTo(self.disposeBag)
  }

  private func setupBindings() {
    self.tableView.rx
      .modelSelected(AppListViewModel.ListItem.self)
      .subscribe(onNext: { [unowned self] in
        self.presentApp(withId: $0.appId)
      })
      .addDisposableTo(self.disposeBag)

    self.tableView.rx
      .itemDeleted
      .map { [unowned self] in
        let item: AppListViewModel.ListItem = try! self.tableView.rx.model($0)
        return item.appId
      }
      .flatMap { [unowned self] in
        self.viewModel.deleteApp(withId: $0)
          .catchErrorJustReturn(())
      }
      .subscribe()
      .addDisposableTo(self.disposeBag)
  }

  private func setupNavigation() {
    self.navigationItem.leftBarButtonItem = self.editButtonItem

    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    rightBarButtonItem.rx.tap
      .flatMapLatest { [weak self] () -> Driver<String?> in
        guard let strongSelf = self else { return Driver.empty() }

        let viewModel = strongSelf.viewModel.newAppConfigViewModel()
        let viewController = AppConfigViewController()
        viewController.viewModel = viewModel
        let navController = UINavigationController(rootViewController: viewController)

        strongSelf.present(navController, animated: true, completion: nil)

        return viewController.finished
      }
      .subscribe(onNext: { [weak self] appDataId in
        guard let strongSelf = self else { return }
        strongSelf.dismiss(animated: true) {
          if let appDataId = appDataId {
            strongSelf.presentApp(withId: appDataId)
          }
        }
      })
      .addDisposableTo(self.disposeBag)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

  private func presentApp(withId appId: String) {
    let storyboard = UIStoryboard(name: "Apps", bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "myElectric")
    if let appVC = viewController as? MyElectricAppViewController {
      let viewModel = self.viewModel.viewModelForApp(withId: appId)
      appVC.viewModel = viewModel
    }
    self.navigationController?.pushViewController(viewController, animated: true)
  }

}
