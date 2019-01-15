//
//  AccountListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import RxDataSources

final class AccountListViewController: UITableViewController {

  var viewModel: AccountListViewModel!

  private let disposeBag = DisposeBag()
  private var firstLoad = true

  private enum Segues: String {
    case addAccount
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Accounts"

    self.setupDataSource()
    self.setupBindings()
    self.setupNavigation()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if self.firstLoad {
      self.firstLoad = false
      if let selectedAccountId = self.viewModel.lastSelectedAccountId {
        self.login(toAccountWithId: selectedAccountId, animated: false)
      }
    }
  }

  private func setupDataSource() {
    let dataSource = RxTableViewSectionedReloadDataSource<AccountListViewModel.Section>(
      configureCell: { (ds, tableView, indexPath, item) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = item.url
        return cell
    },
      titleForHeaderInSection: { _,_  in "" },
      canEditRowAtIndexPath: { _,_  in true },
      canMoveRowAtIndexPath: { _,_  in false })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    self.viewModel.apps
      .map { [AccountListViewModel.Section(model: "", items: $0)] }
      .drive(self.tableView.rx.items(dataSource: dataSource))
      .disposed(by: self.disposeBag)
  }

  private func setupBindings() {
    self.tableView.rx
      .modelSelected(AccountListViewModel.ListItem.self)
      .subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        self.login(toAccountWithId: $0.accountId)
      })
      .disposed(by: self.disposeBag)

    self.tableView.rx
      .itemDeleted
      .map { [unowned self] in
        let item: AccountListViewModel.ListItem = try! self.tableView.rx.model(at: $0)
        return item.accountId
      }
      .flatMap { [unowned self] in
        self.viewModel.deleteAccount(withId: $0)
          .catchErrorJustReturn(())
      }
      .subscribe()
      .disposed(by: self.disposeBag)
  }

  private func setupNavigation() {
    self.navigationItem.leftBarButtonItem = self.editButtonItem

    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    rightBarButtonItem.rx.tap
      .subscribe(onNext: { [weak self] _ in
        guard let self = self else { return }
        self.performSegue(withIdentifier: Segues.addAccount.rawValue, sender: self)
      })
      .disposed(by: self.disposeBag)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

  private func login(toAccountWithId accountId: String, animated: Bool = true) {
    guard let viewModels = self.viewModel.mainViewModels(forAccountWithId: accountId) else {
      return
    }

    self.viewModel.lastSelectedAccountId = accountId

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let rootViewController = storyboard.instantiateViewController(withIdentifier: "MainFlow") as! UITabBarController

    // Setup view models

    let tabBarViewControllers = rootViewController.viewControllers!

    let appListNavController = tabBarViewControllers[0] as! UINavigationController
    let appListViewController = appListNavController.topViewController! as! AppListViewController
    appListViewController.viewModel = viewModels.appList

    let feedListNavController = tabBarViewControllers[1] as! UINavigationController
    let feedListViewController = feedListNavController.topViewController! as! FeedListViewController
    feedListViewController.viewModel = viewModels.feedList

    let settingsNavController = tabBarViewControllers[2] as! UINavigationController
    let settingsViewController = settingsNavController.topViewController! as! SettingsViewController
    settingsViewController.viewModel = viewModels.settings
    settingsViewController.switchAccount
      .asObservable()
      .flatMap { logout -> Observable<()> in
        if logout {
          return self.viewModel.deleteAccount(withId: accountId).becomeVoid()
        } else {
          return Observable.just(())
        }
      }
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [weak self] _ in
        guard let self = self else { return }
        self.dismiss(animated: true, completion: nil)
      })
      .disposed(by: self.disposeBag)

    self.present(rootViewController, animated: animated, completion: nil)
  }

}

extension AccountListViewController {

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.addAccount.rawValue {
      let addAccountViewController = segue.destination as! AddAccountViewController
      let viewModel = self.viewModel.addAccountViewModel()
      addAccountViewController.viewModel = viewModel
      addAccountViewController.finished
        .drive(onNext: { [weak self] accountId in
          guard let self = self else { return }
          guard let accountId = accountId else { return }
          self.navigationController?.popToViewController(self, animated: true)
          self.login(toAccountWithId: accountId)
        })
        .disposed(by: self.disposeBag)
    }
  }

}
