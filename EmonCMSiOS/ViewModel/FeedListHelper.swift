//
//  FeedListHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import RealmSwift

final class FeedListHelper {

  struct FeedListItem {
    let feedId: String
    let name: String
  }

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let feedUpdateHelper: FeedUpdateHelper

  private var cancellables = Set<AnyCancellable>()

  // Inputs
  let refresh = PassthroughSubject<Void, Never>()

  // Outputs
  @Published private(set) var feeds: [FeedListItem] = []
  let isRefreshing: AnyPublisher<Bool, Never>

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.feedUpdateHelper = FeedUpdateHelper(realmController: realmController, account: account, api: api)

    let isRefreshingIndicator = ActivityIndicatorCombine()
    self.isRefreshing = isRefreshingIndicator.asPublisher()

    Publishers.array(from: self.realm.objects(Feed.self))
      .map(self.feedsToListItems)
      .sink(
        receiveCompletion: { error in
          AppLog.error("Query errored when it shouldn't! \(error)")
        },
        receiveValue: { [weak self] items in
          guard let self = self else { return }
          self.feeds = items
        })
      .store(in: &self.cancellables)

    self.refresh
      .map { [weak self] () -> AnyPublisher<(), Never> in
        guard let self = self else { return Empty().eraseToAnyPublisher() }
        return self.feedUpdateHelper.updateFeeds()
          .replaceError(with: ())
          .trackActivity(isRefreshingIndicator)
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .sink(receiveValue: { _ in })
      .store(in: &self.cancellables)
  }

  private func feedsToListItems(_ feeds: [Feed]) -> [FeedListItem] {
    let sortedFeedItems = feeds.sorted {
      $0.name < $1.name
      }.map {
        FeedListItem(feedId: $0.id, name: $0.name)
    }
    return sortedFeedItems
  }

}
