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
    with completion: @escaping (INObjectCollection<FeedIntent>?, Error?) -> Void)
  {
    let collection = self.fetchFeeds()
    completion(collection, nil)
  }

  func provideFeedsOptionsCollection(
    for intent: SelectFeedsIntent,
    with completion: @escaping (INObjectCollection<FeedIntent>?, Error?) -> Void)
  {
    let collection = self.fetchFeeds()
    completion(collection, nil)
  }

  private func fetchFeeds() -> INObjectCollection<FeedIntent> {
    let mainRealm = self.realmController.createMainRealm()
    let accounts = mainRealm.objects(Account.self).sorted(byKeyPath: "name")

    var sections: [INObjectSection<FeedIntent>] = []

    accounts.forEach { account in
      let accountRealm = self.realmController.createAccountRealm(forAccountId: account.uuid)
      let feeds = accountRealm.objects(Feed.self).sorted(byKeyPath: "name")

      var feedIntentsByTag: [String: [FeedIntent]] = [:]
      feeds.forEach { feed in
        let identifier = account.uuid + "/" + feed.id
        let display = feed.name
        let subtitle = feed.tag

        let feedIntent = FeedIntent(
          identifier: identifier,
          display: display,
          subtitle: subtitle,
          image: nil)
        feedIntent.accountId = account.uuid
        feedIntent.feedId = feed.id

        var feedIntents = feedIntentsByTag[feed.tag, default: []]
        feedIntents.append(feedIntent)
        feedIntentsByTag[feed.tag] = feedIntents
      }

      let sortedTags = feedIntentsByTag.keys.sorted { $0.compare($1, options: .numeric) == .orderedAscending }
      let feedIntents = sortedTags.reduce(into: [FeedIntent]()) { $0 += feedIntentsByTag[$1]! }

      sections.append(INObjectSection(title: account.name, items: feedIntents))
    }

    return INObjectCollection(sections: sections)
  }

  func resolveFeed(for intent: SelectFeedIntent, with completion: @escaping (FeedIntentResolutionResult) -> Void) {}
  func resolveFeeds(for intent: SelectFeedsIntent, with completion: @escaping ([FeedIntentResolutionResult]) -> Void) {}

  override func handler(for intent: INIntent) -> Any {
    return self
  }
}
