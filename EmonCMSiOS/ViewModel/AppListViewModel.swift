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
    return Observable.create() { observer in
      do {
        if let app = realm.object(ofType: AppData.self, forPrimaryKey: id) {
          try realm.write {
            realm.delete(app)
          }
        }
        observer.onNext(())
        observer.onCompleted()
      } catch {
        observer.onError(error)
      }

      return Disposables.create()
    }
  }

  func viewController(forDataWithId id: String, ofCategory category: AppCategory) -> UIViewController {
    let storyboard = UIStoryboard(name: "Apps", bundle: nil)
    let viewController = storyboard.instantiateViewController(withIdentifier: category.info.storyboardId)

    switch category {
    case .myElectric:
      let viewModel = MyElectricAppViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: id)
      let appVC = viewController as! MyElectricAppViewController
      appVC.viewModel = viewModel
    case .mySolar:
      let viewModel = MySolarAppViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: id)
      let appVC = viewController as! MySolarAppViewController
      appVC.viewModel = viewModel
    case .mySolarDivert:
      let viewModel = MySolarDivertAppViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: id)
      let appVC = viewController as! MySolarDivertAppViewController
      appVC.viewModel = viewModel
    }

    return viewController
  }

  func appConfigViewModel(forCategory category: AppCategory) -> AppConfigViewModel {
    return AppConfigViewModel(realmController: self.realmController, account: self.account, api: self.api, appDataId: nil, appCategory: category)
  }

}
