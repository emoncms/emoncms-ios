//
//  AccountListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

final class AccountListViewController: UITableViewController {
  var viewModel: AccountListViewModel!

  private var emptyLabel: UILabel?

  private var dataSource: CombineTableViewDataSource<AccountListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()
  private var firstLoad = true

  private enum Segues: String {
    case addAccount
  }

  private struct AddAccountSegueData {
    let accountId: String?
    let animated: Bool
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Accounts"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Lists.Account

    self.setupDataSource()
    self.setupBindings()
    self.setupNavigation()
  }

  private func setupDataSource() {
    let dataSource = CombineTableViewDataSource<AccountListViewModel.Section>(
      configureCell: { _, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = item.url
        return cell
      },
      titleForHeaderInSection: { _, _ in "" },
      canEditRowAtIndexPath: { _, _ in true },
      canMoveRowAtIndexPath: { _, _ in false })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$accounts
      .map { [AccountListViewModel.Section(model: "", items: $0)] }
      .eraseToAnyPublisher()

    dataSource.assign(toTableView: self.tableView, items: items)
    self.dataSource = dataSource
  }

  private func setupBindings() {
    self.dataSource
      .modelSelected
      .sink { [weak self] in
        guard let self = self else { return }
        if self.tableView.isEditing {
          self.performSegue(withIdentifier: Segues.addAccount.rawValue, sender: AddAccountSegueData(accountId: $0.accountId, animated: true))
        } else {
          self.login(toAccountWithId: $0.accountId)
        }
      }
      .store(in: &self.cancellables)

    self.dataSource
      .modelDeleted
      .flatMap { [weak self] item -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty<Void, Never>().eraseToAnyPublisher() }
        return self.viewModel.deleteAccount(withId: item.accountId).replaceError(with: ()).eraseToAnyPublisher()
      }
      .sink { _ in }
      .store(in: &self.cancellables)

    self.viewModel.$accounts
      .dropFirst()
      .map {
        $0.count == 0
      }
      .removeDuplicates()
      .sink { [weak self] empty in
        guard let self = self else { return }

        if self.firstLoad {
          self.firstLoad = false
          if empty {
            self.performSegue(withIdentifier: Segues.addAccount.rawValue, sender: AddAccountSegueData(accountId: nil, animated: false))
          } else if let selectedAccountId = self.viewModel.lastSelectedAccountId {
            self.login(toAccountWithId: selectedAccountId, animated: false)
          }
        }

        if empty {
          let emptyLabel = UILabel(frame: CGRect.zero)
          emptyLabel.translatesAutoresizingMaskIntoConstraints = false
          emptyLabel.text = "Tap + to add a new account"
          emptyLabel.numberOfLines = 0
          emptyLabel.textColor = .lightGray
          self.emptyLabel = emptyLabel

          let tableView = self.tableView!
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
          if let emptyLabel = self.emptyLabel {
            emptyLabel.removeFromSuperview()
          }
        }
      }
      .store(in: &self.cancellables)
  }

  private func setupNavigation() {
    self.navigationItem.leftBarButtonItem = self.editButtonItem

    let rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    rightBarButtonItem.publisher()
      .sink { [weak self] _ in
        guard let self = self else { return }
        self.performSegue(withIdentifier: Segues.addAccount.rawValue, sender: AddAccountSegueData(accountId: nil, animated: true))
      }
      .store(in: &self.cancellables)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

  private func login(toAccountWithId accountId: String, animated: Bool = true) {
    guard let viewModels = self.viewModel.mainViewModels(forAccountWithId: accountId) else {
      return
    }

    self.viewModel.lastSelectedAccountId = accountId

    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    let rootViewController = storyboard.instantiateViewController(withIdentifier: "MainFlow") as! UITabBarController
    rootViewController.modalPresentationStyle = .fullScreen

    // Setup view models

    let tabBarViewControllers = rootViewController.viewControllers!

    let appListNavController = tabBarViewControllers[0] as! UINavigationController
    let appListViewController = appListNavController.topViewController! as! AppListViewController
    appListViewController.viewModel = viewModels.appList

    let inputListNavController = tabBarViewControllers[1] as! UINavigationController
    let inputListViewController = inputListNavController.topViewController! as! InputListViewController
    inputListViewController.viewModel = viewModels.inputList

    let feedListNavController = tabBarViewControllers[2] as! UINavigationController
    let feedListViewController = feedListNavController.topViewController! as! FeedListViewController
    feedListViewController.viewModel = viewModels.feedList

    let dashboardListNavController = tabBarViewControllers[3] as! UINavigationController
    let dashboardListViewController = dashboardListNavController.topViewController! as! DashboardListViewController
    dashboardListViewController.viewModel = viewModels.dashboardList

    let settingsNavController = tabBarViewControllers[4] as! UINavigationController
    let settingsViewController = settingsNavController.topViewController! as! SettingsViewController
    settingsViewController.viewModel = viewModels.settings
    settingsViewController.switchAccount
      .flatMap { logout -> AnyPublisher<Void, Never> in
        if logout {
          return self.viewModel.deleteAccount(withId: accountId).becomeVoid().eraseToAnyPublisher()
        } else {
          return Just(()).eraseToAnyPublisher()
        }
      }
      .replaceError(with: ())
      .sink { [weak self] _ in
        guard let self = self else { return }
        self.dismiss(animated: true, completion: nil)
      }
      .store(in: &self.cancellables)

    self.present(rootViewController, animated: animated, completion: nil)
  }
}

extension AccountListViewController {
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.addAccount.rawValue {
      let data = sender as? AddAccountSegueData
      let addAccountViewController = segue.destination as! AddAccountViewController
      let viewModel = self.viewModel.addAccountViewModel(accountId: data?.accountId)
      addAccountViewController.viewModel = viewModel
      addAccountViewController.finished
        .sink { [weak self] accountId in
          guard let self = self else { return }
          self.navigationController?.popToViewController(self, animated: data?.animated ?? true)
          if data?.accountId == nil {
            guard let accountId = accountId else { return }
            self.login(toAccountWithId: accountId)
          }
        }
        .store(in: &self.cancellables)
    }
  }
}
