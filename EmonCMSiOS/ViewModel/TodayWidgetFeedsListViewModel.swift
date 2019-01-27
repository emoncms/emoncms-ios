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
  private(set) var feeds: Driver<[Section]>

  init(realmController: RealmController, accountController: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.accountController = accountController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createRealm()

    self.feeds = Driver.never()

    let todayWidgetFeedsQuery = self.realm.objects(TodayWidgetFeed.self)
      .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: true)
    self.feeds = Observable.array(from: todayWidgetFeedsQuery)
      .map(self.todayWidgetFeedsToSections)
      .asDriver(onErrorJustReturn: [])
  }

  private func todayWidgetFeedsToSections(_ todayWidgetFeeds: [TodayWidgetFeed]) -> [Section] {
    var sectionBuilder = [String:[ListItem]]()
    var accountIdToName = [String:String]()

    todayWidgetFeeds.forEach { todayWidgetFeed in
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

      let accountController = AccountController(uuid: accountId, dataDirectory: self.realmController.dataDirectory, credentials: AccountCredentials(url: "", apiKey: ""))
      let accountRealm = accountController.createRealm()

      let feedName: String
      if let feed = accountRealm.object(ofType: Feed.self, forPrimaryKey: feedId) {
        feedName = feed.name
      } else {
        feedName = "FAILED TO FIND FEED"
      }

      let listItem = ListItem(todayWidgetFeedId: todayWidgetFeed.uuid, accountId: accountId, accountName: accountName, feedId: feedId, feedName: feedName)

      let sectionItems: [ListItem]
      if let existingItems = sectionBuilder[accountId] {
        sectionItems = existingItems
      } else {
        sectionItems = []
      }
      sectionBuilder[accountId] = sectionItems + [listItem]
    }

    let sections = sectionBuilder.keys
      .sorted { (a, b) in
        if a == self.accountController.uuid {
          return true
        }
        if b == self.accountController.uuid {
          return false
        }
        return a > b
      }
      .map {
        Section(model: accountIdToName[$0]!, items: sectionBuilder[$0]!)
      }

    return sections
  }

  func addTodayWidgetFeed(forFeedId feedId: String) -> Observable<()> {
    let realm = self.realm
    return Observable.deferred { () -> Observable<()> in
      let todayWidgetFeed = TodayWidgetFeed()
      todayWidgetFeed.accountId = self.accountController.uuid
      todayWidgetFeed.feedId = feedId

      try realm.write {
        realm.add(todayWidgetFeed)
      }

      return Observable.just(())
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

  func feedListViewModel() -> FeedListViewModel {
    return FeedListViewModel(account: self.accountController, api: self.api)
  }

}
