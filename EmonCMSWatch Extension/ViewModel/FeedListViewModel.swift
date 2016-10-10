//
//  FeedViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift
import RxRealm

class FeedListViewModel {

  struct ListItem {
    let feedId: String
    let name: String
    let value: String
  }

  private let account: Account
  private let api: EmonCMSAPI
  private let realm: Realm
  private let feedUpdateHelper: FeedUpdateHelper

  private let disposeBag = DisposeBag()

  // Inputs
  let active = Variable<Bool>(false)
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var feeds: Driver<[ListItem]>
  private(set) var isRefreshing: Driver<Bool>

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()
    self.feedUpdateHelper = FeedUpdateHelper(account: account, api: api)

    self.feeds = Driver.never()
    self.isRefreshing = Driver.never()

    self.feeds = Observable.arrayFrom(self.realm.objects(Feed.self))
      .map(self.feedsToListItems)
      .asDriver(onErrorJustReturn: [])

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    let becameActive = self.active.asObservable()
      .distinctUntilChanged()
      .filter { $0 == true }
      .becomeVoid()

    Observable.of(self.refresh, becameActive)
      .merge()
      .flatMapLatest { [weak self] () -> Observable<()> in
        guard let strongSelf = self else { return Observable.empty() }
        return strongSelf.feedUpdateHelper.updateFeeds()
          .catchErrorJustReturn(())
          .trackActivity(isRefreshing)
      }
      .subscribe()
      .addDisposableTo(self.disposeBag)
  }

  private func feedsToListItems(_ feeds: [Feed]) -> [ListItem] {
    let sortedFeedItems = feeds.sorted {
      $0.name < $1.name
      }.map {
        ListItem(feedId: $0.id, name: $0.name, value: $0.value.prettyFormat())
    }
    return sortedFeedItems
  }

}
