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

  struct App {
    let name: String
    let storyboardIdentifier: String
  }

  fileprivate let apps = [
    App(name: "My Electric", storyboardIdentifier: "myElectric")
  ]

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Apps"

    self.setupDataSource()
  }

  private func setupDataSource() {
    self.tableView.delegate = nil
    self.tableView.dataSource = nil
    Observable.just(self.apps)
      .bindTo(self.tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, element, cell) in
        cell.textLabel?.text = element.name
      }
      .addDisposableTo(self.disposeBag)

    self.tableView.rx
      .modelSelected(App.self)
      .subscribe(onNext: { [weak self] (app) in
        guard let strongSelf = self else { return }
        strongSelf.present(app: app)
      })
      .addDisposableTo(self.disposeBag)
  }

  private func present(app: App) {
    // TODO
  }

}
