//
//  FeedUpdateHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import RealmSwift

final class FeedUpdateHelper {

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let scheduler: DispatchQueue

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.scheduler = DispatchQueue(label: "org.openenergymonitor.emoncms.FeedUpdateHelper")
  }

  func updateFeeds() -> AnyPublisher<Void, EmonCMSAPI.APIError> {
    return Deferred {
      return self.api.feedList(self.account.credentials)
        .receive(on: self.scheduler)
        .flatMap { [weak self] feeds -> AnyPublisher<Void, EmonCMSAPI.APIError> in
          guard let self = self else { return Empty().eraseToAnyPublisher() }
          let realm = self.realmController.createAccountRealm(forAccountId: self.account.uuid)
          return self.saveFeeds(feeds, inRealm: realm).eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
    }.eraseToAnyPublisher()
  }

  private func saveFeeds(_ feeds: [Feed], inRealm realm: Realm) -> AnyPublisher<Void, EmonCMSAPI.APIError> {
    return Deferred<AnyPublisher<Void, Never>> { [weak self] in
      guard let self = self else { return Empty().eraseToAnyPublisher() }

      let goneAwayFeeds = realm.objects(Feed.self).filter {
        var inNewArray = false
        for feed in feeds {
          if feed.id == $0.id {
            inNewArray = true
            break
          }
        }
        return !inNewArray
      }

      do {
        try realm.write {
          if goneAwayFeeds.count > 0 {
            realm.delete(goneAwayFeeds)
            let todayWidgetFeedsForGoneAwayFeeds = realm.objects(TodayWidgetFeed.self)
              .filter("accountId = %@ AND feedId IN %@", self.account.uuid, Array(goneAwayFeeds.map { $0.id }))
            realm.delete(todayWidgetFeedsForGoneAwayFeeds)
          }
          realm.add(feeds, update: .all)
        }
      } catch {
        AppLog.error("Failed to write to Realm: \(error)")
      }

      return Just(()).eraseToAnyPublisher()
    }
    .setFailureType(to: EmonCMSAPI.APIError.self)
    .eraseToAnyPublisher()
  }

}
