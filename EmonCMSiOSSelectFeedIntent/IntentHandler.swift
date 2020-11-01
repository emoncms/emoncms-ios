//
//  IntentHandler.swift
//  EmonCMSiOSSelectFeedIntent
//
//  Created by Matt Galloway on 20/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Intents

import Realm
import RealmSwift

class IntentHandler: INExtension, SelectFeedIntentHandling, SelectFeedsIntentHandling {
  private let realmController: RealmController

  override init() {
    let dataDirectory = DataController.sharedDataDirectory
    self.realmController = RealmController(dataDirectory: dataDirectory)

    super.init()
  }

  func provideFeedOptionsCollection(
    for intent: SelectFeedIntent,
    with completion: @escaping (INObjectCollection<FeedIntent>?, Error?) -> Void) {
    let feedIntents = self.fetchFeeds()
    let collection = INObjectCollection(items: Array(feedIntents))
    completion(collection, nil)
  }

  func provideFeedsOptionsCollection(
    for intent: SelectFeedsIntent,
    with completion: @escaping (INObjectCollection<FeedIntent>?, Error?) -> Void) {
    let feedIntents = self.fetchFeeds()
    let collection = INObjectCollection(items: Array(feedIntents))
    completion(collection, nil)
  }

  private func fetchFeeds() -> [FeedIntent] {
    let mainRealm = self.realmController.createMainRealm()
    let accounts = mainRealm.objects(Account.self).sorted(byKeyPath: "name")
    let feedIntents = accounts.flatMap { account -> [FeedIntent] in
      let accountRealm = self.realmController.createAccountRealm(forAccountId: account.uuid)
      let feeds = accountRealm.objects(Feed.self).sorted(byKeyPath: "name")
      return feeds.map { feed in
        let feedIntent = FeedIntent(
          identifier: account.uuid + "/" + feed.id,
          display: feed.name,
          subtitle: account.name,
          image: nil)
        feedIntent.accountId = account.uuid
        feedIntent.feedId = feed.id
        return feedIntent
      }
    }
    return Array(feedIntents)
  }

  func resolveFeed(for intent: SelectFeedIntent, with completion: @escaping (FeedIntentResolutionResult) -> Void) {}
  func resolveFeeds(for intent: SelectFeedsIntent, with completion: @escaping ([FeedIntentResolutionResult]) -> Void) {}

  override func handler(for intent: INIntent) -> Any {
    return self
  }
}
