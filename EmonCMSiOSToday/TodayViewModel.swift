//
//  TodayViewModel.swift
//  EmonCMSiOSToday
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

final class TodayViewModel {
  enum TodayViewModel: Error {
    case unknown
  }

  struct ListItem {
    let accountId: String
    let accountName: String
    let feedId: String
    let feedName: String
    let feedChartData: [DataPoint<Double>]
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let keychainController: KeychainController
  private let api: EmonCMSAPI
  private let realm: Realm

  private var cancellables = Set<AnyCancellable>()

  // Inputs

  // Outputs
  @Published private(set) var feeds: [ListItem] = []

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createMainRealm()
  }

  func updateData() -> AnyPublisher<Bool, Never> {
    return Deferred { [weak self] () -> AnyPublisher<Bool, Never> in
      guard let self = self else { return Empty<Bool, Never>().eraseToAnyPublisher() }

      let feedsQuery = self.realm.objects(TodayWidgetFeed.self)
        .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: true)

      let listItemObservables = feedsQuery.compactMap { [weak self] todayWidgetFeed -> AnyPublisher<ListItem?, Never>? in
        guard let self = self else { return nil }

        let accountId = todayWidgetFeed.accountId
        let feedId = todayWidgetFeed.feedId

        guard
          let account = self.realm.object(ofType: Account.self, forPrimaryKey: accountId),
          let apiKey = self.keychainController.apiKey(forAccountWithId: accountId)
        else { return nil }

        let accountName = account.name
        let accountCredentials = AccountCredentials(url: account.url, apiKey: apiKey)
        let accountRealm = self.realmController.createAccountRealm(forAccountId: accountId)

        guard let feed = accountRealm.object(ofType: Feed.self, forPrimaryKey: feedId) else { return nil }

        let feedName = feed.name

        let range = 3600
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(TimeInterval(-range))
        return self.api.feedData(accountCredentials, id: feedId, at: startDate, until: endDate, interval: range / 200)
          .replaceError(with: [])
          .map { dataPoints -> ListItem in
            ListItem(
              accountId: accountId,
              accountName: accountName,
              feedId: feedId,
              feedName: feedName,
              feedChartData: dataPoints)
          }
          .eraseToAnyPublisher()
      }

      if listItemObservables.count == 0 {
        self.feeds = []
        return Just<Bool>(true).eraseToAnyPublisher()
      } else {
        return listItemObservables.publisher.flatMap { $0 }.collect()
          .handleEvents(receiveOutput: { [weak self] in
            guard let self = self else { return }
            let nonNils = $0.compactMap { $0 }
            self.feeds = nonNils
          })
          .map { _ in true }
          .eraseToAnyPublisher()
      }
    }.eraseToAnyPublisher()
  }
}
