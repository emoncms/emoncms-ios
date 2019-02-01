//
//  AppsListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift
import RxDataSources

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

  private let disposeBag = DisposeBag()

  // Inputs

  // Outputs
  private(set) var apps: Driver<[ListItem]>

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)

    self.apps = Driver.never()

    let appQuery = self.realm.objects(AppData.self)
      .sorted(byKeyPath: #keyPath(AppData.name), ascending: true)
    self.apps = Observable.array(from: appQuery)
      .map(self.appsToListItems)
      .asDriver(onErrorJustReturn: [])
  }

  private func appsToListItems(_ apps: [AppData]) -> [ListItem] {
    let listItems = apps.map {
      ListItem(appId: $0.uuid, category: $0.appCategory, name: $0.name)
    }
    return listItems
  }

  func deleteApp(withId id: String) -> Observable<()> {
    let realm = self.realm
    return Observable.deferred {
      if let app = realm.object(ofType: AppData.self, forPrimaryKey: id) {
        try realm.write {
          realm.delete(app)
        }
      }
      return Observable.just(())
    }
  }

  func viewController(forDataWithId id: String, ofCategory category: AppCategory) -> UIViewController {
    let storyboard = UIStoryboard(name: "Apps", bundle: nil)
    let appViewController = storyboard.instantiateInitialViewController() as! AppViewController

    let viewModel: AppViewModel
    switch category {
    case .myElectric:
      viewModel = MyElectricAppViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: id)
    case .mySolar:
      viewModel = MySolarAppViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: id)
    case .mySolarDivert:
      viewModel = MySolarDivertAppViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: id)
    }
    appViewController.viewModel = viewModel

    return appViewController
  }

  func appConfigViewModel(forCategory category: AppCategory) -> AppConfigViewModel {
    return AppConfigViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: nil, appCategory: category)
  }

}
