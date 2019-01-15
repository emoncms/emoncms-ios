//
//  FeedListHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 10/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class FeedListHelper {

  struct FeedListItem {
    let feedId: String
    let name: String
  }

  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let feedUpdateHelper: FeedUpdateHelper

  private let disposeBag = DisposeBag()

  // Inputs
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var feeds: Driver<[FeedListItem]>
  private(set) var isRefreshing: Driver<Bool>

  init(account: AccountController, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()
    self.feedUpdateHelper = FeedUpdateHelper(account: account, api: api)

    self.feeds = Driver.never()
    self.isRefreshing = Driver.never()

    self.feeds = Observable.array(from: self.realm.objects(Feed.self))
      .map(self.feedsToListItems)
      .asDriver(onErrorJustReturn: [])

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    self.refresh
      .flatMapLatest { [weak self] () -> Observable<()> in
        guard let strongSelf = self else { return Observable.empty() }
        return strongSelf.feedUpdateHelper.updateFeeds()
          .catchErrorJustReturn(())
          .trackActivity(isRefreshing)
      }
      .subscribe()
      .disposed(by: self.disposeBag)
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
