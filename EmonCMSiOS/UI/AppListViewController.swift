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

class AppListViewController: UITableViewController {

  var viewModel: AppListViewModel!

  fileprivate let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Apps"

    self.setupDataSource()
  }

  private func setupDataSource() {
    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.apps
      .bindTo(self.tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, element, cell) in
        cell.textLabel?.text = element.name
      }
      .addDisposableTo(self.disposeBag)

    self.tableView.rx
      .modelSelected(AppListViewModel.App.self)
      .subscribe(onNext: { [weak self] (app) in
        guard let strongSelf = self else { return }
        strongSelf.present(app: app)
      })
      .addDisposableTo(self.disposeBag)
  }

  private func present(app: AppListViewModel.App) {
    let storyboard = UIStoryboard(name: "Apps", bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: app.storyboardIdentifier)
    if let appVC = viewController as? AppViewController {
      let viewModel = app.viewModelGenerator()
      appVC.genericViewModel = viewModel
    }
    self.navigationController?.pushViewController(viewController, animated: true)
  }

}
