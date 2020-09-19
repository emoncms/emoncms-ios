//
//  AppsListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation
import UIKit

import RealmSwift

final class AppListViewModel {
  struct ListItem {
    let appId: String
    let category: AppCategory
    let name: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm

  private var cancellables = Set<AnyCancellable>()

  // Inputs

  // Outputs
  @Published private(set) var apps: [ListItem] = []

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)

    let appQuery = self.realm.objects(AppData.self)
      .sorted(byKeyPath: #keyPath(AppData.name), ascending: true)
    appQuery.collectionPublisher
      .map(self.appsToListItems)
      .sink(
        receiveCompletion: { error in
          AppLog.error("Query errored when it shouldn't! \(error)")
        },
        receiveValue: { [weak self] items in
          guard let self = self else { return }
          self.apps = items
        })
      .store(in: &self.cancellables)
  }

  private func appsToListItems(_ apps: Results<AppData>) -> [ListItem] {
    let listItems = apps.map {
      ListItem(appId: $0.uuid, category: $0.appCategory, name: $0.name)
    }
    return Array(listItems)
  }

  func deleteApp(withId id: String) -> AnyPublisher<Void, Never> {
    let realm = self.realm
    return Deferred { () -> Just<Void> in
      do {
        if let app = realm.object(ofType: AppData.self, forPrimaryKey: id) {
          try realm.write {
            realm.delete(app)
          }
        }
      } catch {}

      return Just(())
    }.eraseToAnyPublisher()
  }

  func viewController(forDataWithId id: String, ofCategory category: AppCategory) -> UIViewController {
    let storyboard = UIStoryboard(name: "Apps", bundle: nil)
    let appViewController = storyboard.instantiateInitialViewController() as! AppViewController

    let viewModel = category.viewModelInit(self.realmController, self.account, self.api, id)
    appViewController.viewModel = viewModel

    return appViewController
  }

  func appConfigViewModel(forCategory category: AppCategory) -> AppConfigViewModel {
    return AppConfigViewModel(realmController: self.realmController, account: self.account, api: self.api,
                              appDataId: nil, appCategory: category)
  }
}
