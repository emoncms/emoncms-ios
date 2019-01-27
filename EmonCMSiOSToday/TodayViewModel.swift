//
//  TodayViewModel.swift
//  EmonCMSiOSToday
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import RxRealm

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

  private let disposeBag = DisposeBag()

  // Inputs

  // Outputs
  lazy var feeds: Driver<[ListItem]> = {
    return self.feedsSubject.asDriver(onErrorJustReturn: [])
  }()
  private var feedsSubject = ReplaySubject<[ListItem]>.create(bufferSize: 1)

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createRealm()
  }

  func updateData() -> Observable<Bool> {
    return Observable.deferred { [weak self] in
      guard let self = self else { return Observable.empty() }

      let feedsQuery = self.realm.objects(TodayWidgetFeed.self)
        .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: true)

      let listItemObservables = feedsQuery.compactMap { [weak self] todayWidgetFeed -> Observable<ListItem?>? in
        guard let self = self else { return nil }

        let accountId = todayWidgetFeed.accountId
        let feedId = todayWidgetFeed.feedId

        guard
          let account = self.realm.object(ofType: Account.self, forPrimaryKey: accountId),
          let apiKey = self.keychainController.apiKey(forAccountWithId: accountId)
          else { return nil }

        let accountName = account.name
        let accountCredentials = AccountCredentials(url: account.url, apiKey: apiKey)
        let accountController = AccountController(uuid: accountId, dataDirectory: self.realmController.dataDirectory, credentials: accountCredentials)
        let accountRealm = accountController.createRealm()

        guard let feed = accountRealm.object(ofType: Feed.self, forPrimaryKey: feedId) else { return nil }

        let feedName = feed.name

        let range = 3600
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(TimeInterval(-range))
        return self.api.feedData(accountCredentials, id: feedId, at: startDate, until: endDate, interval: (range / 200))
          .catchErrorJustReturn([])
          .map { dataPoints -> ListItem in
            return ListItem(
              accountId: accountId,
              accountName: accountName,
              feedId: feedId,
              feedName: feedName,
              feedChartData: dataPoints
            )
          }
      }

      return Observable.zip(listItemObservables)
        .do(onNext: { [weak self] in
          guard let self = self else { return }
          let nonNils = $0.compactMap { $0 }
          self.feedsSubject.onNext(nonNils)
        })
        .map { _ in return true }
    }
  }

}
