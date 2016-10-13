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

class AppListViewModel {

  struct ListItem {
    let appId: String
    let name: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let account: Account
  private let api: EmonCMSAPI
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs

  // Outputs
  private(set) var apps: Driver<[ListItem]>

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()

    self.apps = Driver.never()

    let appQuery = self.realm.objects(MyElectricAppData.self)
      .sorted(byProperty: #keyPath(MyElectricAppData.name), ascending: true)
    self.apps = Observable.arrayFrom(appQuery)
      .map(self.appsToListItems)
      .asDriver(onErrorJustReturn: [])
  }

  private func appsToListItems(_ apps: [MyElectricAppData]) -> [ListItem] {
    let listItems = apps.map {
      ListItem(appId: $0.uuid, name: $0.name)
    }
    return listItems
  }

  func viewModelForApp(withId id: String) -> MyElectricAppViewModel {
    return MyElectricAppViewModel(account: self.account, api: self.api, appDataId: id)
  }

  func newAppConfigViewModel() -> MyElectricAppConfigViewModel {
    return MyElectricAppConfigViewModel(account: self.account, api: self.api, appDataId: nil)
  }

  func deleteApp(withId id: String) -> Observable<()> {
    let realm = self.realm
    return Observable.create() { observer in
      do {
        if let app = realm.object(ofType: MyElectricAppData.self, forPrimaryKey: id) {
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

}
