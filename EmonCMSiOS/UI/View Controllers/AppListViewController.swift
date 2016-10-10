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

class AppListViewController: UITableViewController {

  var viewModel: AppListViewModel!

  fileprivate let dataSource = RxTableViewSectionedReloadDataSource<AppListViewModel.Section>()
  fileprivate let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Apps"

    self.navigationItem.leftBarButtonItem = self.editButtonItem
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

    self.setupDataSource()
    self.setupBindings()
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
      .modelSelected(AppListViewModel.AppListItem.self)
      .subscribe(onNext: { [unowned self] in
        self.present(app: $0)
      })
      .addDisposableTo(self.disposeBag)

    self.tableView.rx
      .itemDeleted
      .map { [unowned self] in
        let item: AppListViewModel.AppListItem = try! self.tableView.rx.model($0)
        return item.appId
      }
      .flatMap { [unowned self] in
        self.viewModel.deleteApp(withId: $0)
          .catchErrorJustReturn(())
      }
      .subscribe()
      .addDisposableTo(self.disposeBag)

    let rightBarButtonItem = self.navigationItem.rightBarButtonItem!
    rightBarButtonItem.rx.tap
      .flatMapLatest { [unowned self] in
        self.viewModel.addApp()
          .catchErrorJustReturn(())
      }
      .subscribe()
      .addDisposableTo(self.disposeBag)
  }

  private func present(app: AppListViewModel.AppListItem) {
    let storyboard = UIStoryboard(name: "Apps", bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: "myElectric")
    if let appVC = viewController as? MyElectricAppViewController {
      let viewModel = self.viewModel.viewModelForApp(withId: app.appId)
      appVC.viewModel = viewModel
    }
    self.navigationController?.pushViewController(viewController, animated: true)
  }

}
