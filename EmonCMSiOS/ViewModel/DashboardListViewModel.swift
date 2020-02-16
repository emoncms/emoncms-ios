//
//  DashboardListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

final class DashboardListViewModel {
  struct ListItem {
    let dashboardId: String
    let name: String
    let desc: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let dashboardUpdateHelper: DashboardUpdateHelper

  private var cancellables = Set<AnyCancellable>()

  // Inputs
  @Published var active = false
  let refresh = PassthroughSubject<Void, Never>()

  // Outputs
  @Published private(set) var dashboards: [ListItem] = []
  @Published private(set) var updateTime: Date? = nil
  let isRefreshing: AnyPublisher<Bool, Never>
  @Published private(set) var serverNeedsUpdate = false

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.dashboardUpdateHelper = DashboardUpdateHelper(realmController: realmController, account: account, api: api)

    let isRefreshingIndicator = ActivityIndicatorCombine()
    self.isRefreshing = isRefreshingIndicator.asPublisher()

    let dashboardsQuery = self.realm.objects(Dashboard.self).sorted(byKeyPath: #keyPath(Dashboard.id))
    Publishers.array(from: dashboardsQuery)
      .map(self.dashboardsToListItems)
      .sink(
        receiveCompletion: { error in
          AppLog.error("Query errored when it shouldn't! \(error)")
        },
        receiveValue: { [weak self] items in
          guard let self = self else { return }
          self.dashboards = items
          self.updateTime = Date()
        })
      .store(in: &self.cancellables)

    let becameActive = $active
      .filter { $0 == true }
      .removeDuplicates()
      .becomeVoid()

    Publishers.Merge(self.refresh, becameActive)
      .map { [weak self] () -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty().eraseToAnyPublisher() }
        return self.dashboardUpdateHelper.updateDashboards()
          .catch { [weak self] error -> AnyPublisher<Void, Never> in
            if error == EmonCMSAPI.APIError.invalidResponse {
              self?.serverNeedsUpdate = true
            }
            return Just(()).eraseToAnyPublisher()
          }
          .trackActivity(isRefreshingIndicator)
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .sink(receiveValue: { _ in })
      .store(in: &self.cancellables)
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
