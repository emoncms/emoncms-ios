//
//  FeedUpdateHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class FeedUpdateHelper {

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let scheduler: SerialDispatchQueueScheduler

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "org.openenergymonitor.emoncms.FeedUpdateHelper")
  }

  func updateFeeds() -> Observable<()> {
    return Observable.deferred {
      return self.api.feedList(self.account.credentials)
        .observeOn(self.scheduler)
        .flatMap { [weak self] feeds -> Observable<()> in
          guard let self = self else { return Observable.empty() }
          let realm = self.realmController.createAccountRealm(forAccountId: self.account.uuid)
          return self.saveFeeds(feeds, inRealm: realm)
        }
        .observeOn(MainScheduler.asyncInstance)
    }
  }

  private func saveFeeds(_ feeds: [Feed], inRealm realm: Realm) -> Observable<()> {
    return Observable.create() { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      do {
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

        try realm.write {
          if goneAwayFeeds.count > 0 {
            realm.delete(goneAwayFeeds)
            let todayWidgetFeedsForGoneAwayFeeds = realm.objects(TodayWidgetFeed.self)
              .filter("accountId = %@ AND feedId IN %@", self.account.uuid, Array(goneAwayFeeds.map { $0.id }))
            realm.delete(todayWidgetFeedsForGoneAwayFeeds)
          }
          realm.add(feeds, update: true)
        }
        observer.onNext(())
        observer.onCompleted()
      } catch {
        observer.onError(error)
      }

      return Disposables.create()
    }
  }

}
