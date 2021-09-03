//
//  AppListViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import UIKit

final class AppListViewController: UITableViewController {
  var viewModel: AppListViewModel!

  private var emptyLabel: UILabel?

  private var dataSource: CombineTableViewDataSource<AppListViewModel.Section>!
  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "Apps"
    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Lists.App

    self.setupDataSource()
    self.setupBindings()
    self.setupNavigation()
  }

  private func setupDataSource() {
    let dataSource = CombineTableViewDataSource<AppListViewModel.Section>(
      configureCell: { _, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = item.category.displayName
        return cell
      },
      titleForHeaderInSection: { _, _ in "" },
      canEditRowAtIndexPath: { _, _ in true },
      canMoveRowAtIndexPath: { _, _ in false })

    self.tableView.delegate = nil
    self.tableView.dataSource = nil

    let items = self.viewModel.$apps
      .map { [AppListViewModel.Section(model: "", items: $0)] }
      .eraseToAnyPublisher()

    dataSource.assign(toTableView: self.tableView, items: items)
    self.dataSource = dataSource
  }

  private func setupBindings() {
    self.dataSource
      .modelSelected
      .sink { [weak self] in
        self?.presentApp(withId: $0.appId, ofCategory: $0.category)
      }
      .store(in: &self.cancellables)

    self.dataSource
      .modelDeleted
      .flatMap { [weak self] item -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty<Void, Never>().eraseToAnyPublisher() }
        return self.viewModel.deleteApp(withId: item.appId).replaceError(with: ()).eraseToAnyPublisher()
      }
      .sink { _ in }
      .store(in: &self.cancellables)

    self.viewModel.$apps
      .map {
        $0.count == 0
      }
      .removeDuplicates()
      .sink { [weak self] empty in
        guard let self = self else { return }

        if empty {
          let emptyLabel = UILabel(frame: CGRect.zero)
          emptyLabel.translatesAutoresizingMaskIntoConstraints = false
          emptyLabel.text = "Tap + to add a new app"
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
      .map { [weak self] _ -> AnyPublisher<AppCategory, Never> in
        guard let self = self else { return Empty<AppCategory, Never>().eraseToAnyPublisher() }

        let alert = UIAlertController(title: "Select a type", message: nil, preferredStyle: .actionSheet)

        return Producer<AppCategory, Never> { observer in
          alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            observer.receive(completion: .finished)
          })

          AppCategory.allCases.forEach { appCategory in
            alert.addAction(UIAlertAction(title: appCategory.displayName, style: .default) { _ in
              _ = observer.receive(appCategory)
              observer.receive(completion: .finished)
            })
          }

          if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = rightBarButtonItem
          }

          self.present(alert, animated: true, completion: nil)
        }
        .handleEvents(receiveCancel: {
          alert.dismiss(animated: true, completion: nil)
        })
        .eraseToAnyPublisher()
      }
      .switchToLatest()
      .map { [weak self] appCategory -> AnyPublisher<AppUUIDAndCategory?, Never> in
        guard let self = self else { return Empty<AppUUIDAndCategory?, Never>().eraseToAnyPublisher() }

        let viewModel = self.viewModel.appConfigViewModel(forCategory: appCategory)
        let viewController = AppConfigViewController()
        viewController.viewModel = viewModel
        let navController = UINavigationController(rootViewController: viewController)

        self.present(navController, animated: true, completion: nil)

        return viewController.finished
      }
      .switchToLatest()
      .sink { [weak self] appUUIDAndCategory in
        guard let self = self else { return }
        self.dismiss(animated: true) {
          if let appUUIDAndCategory = appUUIDAndCategory {
            self.presentApp(withId: appUUIDAndCategory.uuid, ofCategory: appUUIDAndCategory.category)
          }
        }
      }
      .store(in: &self.cancellables)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

  private func presentApp(withId appId: String, ofCategory category: AppCategory) {
    let viewController = self.viewModel.viewController(forDataWithId: appId, ofCategory: category)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
}
