//
//  TodayWidgetFeedsListViewModel.swift
//  EmonCMSiOS
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

final class TodayWidgetFeedsListViewModel {

  struct ListItem {
    let todayWidgetFeedId: String
    let accountId: String
    let accountName: String
    let feedId: String
    let feedName: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let accountController: AccountController
  private let keychainController: KeychainController
  private let api: EmonCMSAPI
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs

  // Outputs
  private(set) var feeds: Driver<[ListItem]>

  init(realmController: RealmController, accountController: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.accountController = accountController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createMainRealm()

    self.feeds = Driver.never()

    let todayWidgetFeedsQuery = self.realm.objects(TodayWidgetFeed.self)
      .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: true)
    self.feeds = Observable.array(from: todayWidgetFeedsQuery)
      .map(self.todayWidgetFeedsToListItems)
      .asDriver(onErrorJustReturn: [])
  }

  private func todayWidgetFeedsToListItems(_ todayWidgetFeeds: [TodayWidgetFeed]) -> [ListItem] {
    var accountIdToName = [String:String]()

    let listItems = todayWidgetFeeds.map { todayWidgetFeed -> ListItem in
      let accountId = todayWidgetFeed.accountId
      let feedId = todayWidgetFeed.feedId

      let accountName: String
      if let name = accountIdToName[accountId] {
        accountName = name
      } else if let account = self.realm.object(ofType: Account.self, forPrimaryKey: accountId) {
        accountName = account.name
        accountIdToName[accountId] = accountName
      } else {
        accountName = "FAILED TO FIND ACCOUNT"
      }

      let accountRealm = self.realmController.createAccountRealm(forAccountId: accountId)

      let feedName: String
      if let feed = accountRealm.object(ofType: Feed.self, forPrimaryKey: feedId) {
        feedName = feed.name
      } else {
        feedName = "FAILED TO FIND FEED"
      }

      return ListItem(todayWidgetFeedId: todayWidgetFeed.uuid, accountId: accountId, accountName: accountName, feedId: feedId, feedName: feedName)
    }

    return listItems
  }

  func addTodayWidgetFeed(forFeedId feedId: String) -> Observable<Bool> {
    let realm = self.realm
    return Observable.deferred { () -> Observable<Bool> in
      let query = realm.objects(TodayWidgetFeed.self).filter("accountId = %@ AND feedId = %@", self.accountController.uuid, feedId)
      guard query.count == 0 else { return Observable.just(false) }

      let todayWidgetFeed = TodayWidgetFeed()
      todayWidgetFeed.accountId = self.accountController.uuid
      todayWidgetFeed.feedId = feedId

      let maxOrderObject = realm.objects(TodayWidgetFeed.self)
        .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: false)
        .first
      let maxOrder = maxOrderObject?.order ?? 0

      todayWidgetFeed.order = maxOrder + 1

      try realm.write {
        realm.add(todayWidgetFeed)
      }

      return Observable.just(true)
    }
  }

  func deleteTodayWidgetFeed(withId id: String) -> Observable<()> {
    let realm = self.realm
    return Observable.deferred { () -> Observable<()> in
      if let todayWidgetFeed = realm.object(ofType: TodayWidgetFeed.self, forPrimaryKey: id) {
        try realm.write {
          realm.delete(todayWidgetFeed)
        }
      }

      return Observable.just(())
    }
  }

  func moveTodayWidgetFeed(fromIndex oldIndex: Int, toIndex newIndex: Int) -> Observable<()> {
    let realm = self.realm
    return Observable.deferred { () -> Observable<()> in
      let query = self.realm.objects(TodayWidgetFeed.self)
        .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: true)

      var objects = Array(query)
      guard oldIndex < objects.count && newIndex < objects.count else { return Observable.empty() }

      let moveObject = objects.remove(at: oldIndex)
      objects.insert(moveObject, at: newIndex)

      try realm.write {
        var i = 0
        objects.forEach { item in
          item.order = i
          i += 1
        }
      }

      return Observable.just(())
    }
  }

  func feedListViewModel() -> FeedListViewModel {
    return FeedListViewModel(realmController: self.realmController, account: self.accountController, api: self.api)
  }

}
