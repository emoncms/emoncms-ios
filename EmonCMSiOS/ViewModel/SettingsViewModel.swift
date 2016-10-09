//
//  SettingsViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift
import WatchConnectivity

class SettingsViewModel {

  struct FeedListItem {
    let feedId: String
    let name: String
  }

  private let account: Account
  private let api: EmonCMSAPI
  private let watchController: WatchController
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs
  let active = Variable<Bool>(false)
  let refreshFeeds = ReplaySubject<()>.create(bufferSize: 1)
  let watchFeed = Variable<FeedListItem?>(nil)

  // Outputs
  private(set) var feeds: Driver<[FeedListItem]>
  private(set) var isRefreshingFeeds: Driver<Bool>
  var showWatchSection: Bool {
    return self.watchController.isPaired && self.watchController.isWatchAppInstalled
  }

  init(account: Account, api: EmonCMSAPI, watchController: WatchController) {
    self.account = account
    self.api = api
    self.watchController = watchController
    self.realm = account.createRealm()

    self.feeds = Driver.never()
    self.isRefreshingFeeds = Driver.never()

    self.feeds = Observable.arrayFrom(self.realm.objects(Feed.self))
      .map(self.feedsToListItems)
      .asDriver(onErrorJustReturn: [])

    let isRefreshingFeeds = ActivityIndicator()
    self.isRefreshingFeeds = isRefreshingFeeds.asDriver()

    let becameActive = self.active.asObservable()
      .distinctUntilChanged()
      .filter { $0 == true }
      .becomeVoid()

    Observable.of(self.refreshFeeds, becameActive)
      .merge()
      .flatMapLatest { [weak self] () -> Observable<()> in
        guard let strongSelf = self else { return Observable.empty() }
        return strongSelf.api.feedList(account)
          .flatMap(strongSelf.saveFeeds)
          .catchErrorJustReturn(())
          .trackActivity(isRefreshingFeeds)
      }
      .subscribe()
      .addDisposableTo(self.disposeBag)

    if let feedId = self.watchController.complicationFeedId.value {
      self.watchFeed.value = FeedListItem(feedId: feedId, name: "")
    }

    self.watchFeed
      .asDriver()
      .map { $0?.feedId }
      .drive(self.watchController.complicationFeedId)
      .addDisposableTo(self.disposeBag)
  }

  private func saveFeeds(_ feeds: [Feed]) -> Observable<()> {
    let realm = self.realm
    return Observable.create() { observer in
      do {
        try realm.write {
          realm.add(feeds, update: true)
        }
        observer.onNext(())
        observer.onCompleted()
      } catch {
        observer.onError(error)
      }

      return Disposables.create()
    }.subscribeOn(MainScheduler.asyncInstance)
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
