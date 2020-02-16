//
//  TodayWidgetFeedsListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 27/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

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

  private var cancellables = Set<AnyCancellable>()

  // Inputs

  // Outputs
  @Published private(set) var feeds: [ListItem] = []

  init(realmController: RealmController, accountController: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.accountController = accountController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createMainRealm()

    let todayWidgetFeedsQuery = self.realm.objects(TodayWidgetFeed.self)
      .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: true)
    Publishers.array(from: todayWidgetFeedsQuery)
      .map(self.todayWidgetFeedsToListItems)
      .sink(
        receiveCompletion: { error in
          AppLog.error("Query errored when it shouldn't! \(error)")
        },
        receiveValue: { [weak self] items in
          guard let self = self else { return }
          self.feeds = items
        })
      .store(in: &self.cancellables)
  }

  private func todayWidgetFeedsToListItems(_ todayWidgetFeeds: [TodayWidgetFeed]) -> [ListItem] {
    var accountIdToName = [String: String]()

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

      return ListItem(todayWidgetFeedId: todayWidgetFeed.uuid, accountId: accountId, accountName: accountName,
                      feedId: feedId, feedName: feedName)
    }

    return listItems
  }

  func addTodayWidgetFeed(forFeedId feedId: String) -> AnyPublisher<Bool, Never> {
    let realm = self.realm
    return Deferred { () -> Just<Bool> in
      let query = realm.objects(TodayWidgetFeed.self)
        .filter("accountId = %@ AND feedId = %@", self.accountController.uuid, feedId)
      guard query.count == 0 else { return Just(false) }

      let todayWidgetFeed = TodayWidgetFeed()
      todayWidgetFeed.accountId = self.accountController.uuid
      todayWidgetFeed.feedId = feedId

      let maxOrderObject = realm.objects(TodayWidgetFeed.self)
        .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: false)
        .first
      let maxOrder = maxOrderObject?.order ?? 0

      todayWidgetFeed.order = maxOrder + 1

      do {
        try realm.write {
          realm.add(todayWidgetFeed)
        }

        return Just(true)
      } catch {
        return Just(false)
      }
    }.eraseToAnyPublisher()
  }

  func deleteTodayWidgetFeed(withId id: String) -> AnyPublisher<Void, Never> {
    let realm = self.realm
    return Deferred { () -> Just<Void> in
      do {
        if let todayWidgetFeed = realm.object(ofType: TodayWidgetFeed.self, forPrimaryKey: id) {
          try realm.write {
            realm.delete(todayWidgetFeed)
          }
        }
      } catch {}

      return Just(())
    }.eraseToAnyPublisher()
  }

  func moveTodayWidgetFeed(fromIndex oldIndex: Int, toIndex newIndex: Int) -> AnyPublisher<Void, Never> {
    let realm = self.realm
    return Deferred { () -> Just<Void> in
      let query = self.realm.objects(TodayWidgetFeed.self)
        .sorted(byKeyPath: #keyPath(TodayWidgetFeed.order), ascending: true)

      var objects = Array(query)
      guard oldIndex < objects.count, newIndex < objects.count else { return Just(()) }

      let moveObject = objects.remove(at: oldIndex)
      objects.insert(moveObject, at: newIndex)

      do {
        try realm.write {
          var i = 0
          objects.forEach { item in
            item.order = i
            i += 1
          }
        }
      } catch {}

      return Just(())
    }.eraseToAnyPublisher()
  }

  func feedListViewModel() -> FeedListViewModel {
    return FeedListViewModel(realmController: self.realmController, account: self.accountController, api: self.api)
  }
}
