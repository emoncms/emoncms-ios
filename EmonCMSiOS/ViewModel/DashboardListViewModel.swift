//
//  DashboardListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import RxRealm

final class DashboardListViewModel {

  struct ListItem {
    let dashboardId: String
    let name: String
    let desc: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let dashboardUpdateHelper: DashboardUpdateHelper

  private let disposeBag = DisposeBag()

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var dashboards: Driver<[ListItem]>
  private(set) var updateTime: Driver<Date?>
  private(set) var isRefreshing: Driver<Bool>
  lazy var serverNeedsUpdate: Driver<Bool> = {
    return self.serverNeedsUpdateSubject.asDriver(onErrorJustReturn: true).distinctUntilChanged()
  }()
  private var serverNeedsUpdateSubject = PublishSubject<Bool>()

  init(account: AccountController, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()
    self.dashboardUpdateHelper = DashboardUpdateHelper(account: account, api: api)

    self.dashboards = Driver.never()
    self.updateTime = Driver.never()
    self.isRefreshing = Driver.never()

    let dashboardsQuery = self.realm.objects(Dashboard.self).sorted(byKeyPath: #keyPath(Dashboard.id))
    self.dashboards = Observable.array(from: dashboardsQuery)
      .map(self.dashboardsToListItems)
      .asDriver(onErrorJustReturn: [])

    self.updateTime = self.dashboards
      .map { _ in Date() }
      .startWith(nil)
      .asDriver(onErrorJustReturn: Date())

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    let becameActive = self.active.asObservable()
      .distinctUntilChanged()
      .filter { $0 == true }
      .becomeVoid()

    Observable.of(self.refresh, becameActive)
      .merge()
      .flatMapLatest { [weak self] () -> Observable<()> in
        guard let self = self else { return Observable.empty() }
        return self.dashboardUpdateHelper.updateDashboards()
          .catchError { [weak self] error in
            if error == EmonCMSAPI.APIError.invalidResponse {
              self?.serverNeedsUpdateSubject.onNext(true)
            }
            throw error
          }
          .catchErrorJustReturn(())
          .trackActivity(isRefreshing)
      }
      .subscribe()
      .disposed(by: self.disposeBag)
  }

  private func dashboardsToListItems(_ dashboards: [Dashboard]) -> [ListItem] {
    let listItems = dashboards.map {
      ListItem(dashboardId: $0.id, name: $0.name, desc: $0.desc)
    }
    return listItems
  }

  func urlForDashboard(withId id: String) -> URL? {
    let fullUrl = self.account.credentials.url + "/dashboard/view?id=\(id)&embed=1&apikey=\(self.account.credentials.apiKey)"
    guard let dashboardURL = URL(string: fullUrl) else { return nil }
    return dashboardURL
  }

}
