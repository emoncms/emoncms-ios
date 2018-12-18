//
//  FeedListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import RxRealm

final class FeedListViewModel {

  struct ListItem {
    let feedId: String
    let name: String
    let time: Date
    let value: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let account: Account
  private let api: EmonCMSAPI
  private let realm: Realm
  private let feedUpdateHelper: FeedUpdateHelper

  private let disposeBag = DisposeBag()

  // Inputs
  let active = Variable<Bool>(false)
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var feeds: Driver<[Section]>
  private(set) var isRefreshing: Driver<Bool>

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()
    self.feedUpdateHelper = FeedUpdateHelper(account: account, api: api)

    self.feeds = Driver.never()
    self.isRefreshing = Driver.never()

    self.feeds = Observable.array(from: self.realm.objects(Feed.self))
      .map(self.feedsToSections)
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
      .disposed(by: self.disposeBag)
  }

  private func feedsToSections(_ feeds: [Feed]) -> [Section] {
    var sectionBuilder: [String:[Feed]] = [:]
    for feed in feeds {
      let sectionFeeds: [Feed]
      if let existingFeeds = sectionBuilder[feed.tag] {
        sectionFeeds = existingFeeds
      } else {
        sectionFeeds = []
      }
      sectionBuilder[feed.tag] = sectionFeeds + [feed]
    }

    var sections: [Section] = []
    for section in sectionBuilder.keys.sorted() {
      let items = sectionBuilder[section]!
        .map { feed in
          return ListItem(feedId: feed.id, name: feed.name, time: feed.time, value: feed.value.prettyFormat())
        }
      sections.append(Section(model: section, items: items))
    }

    return sections
  }

  func feedChartViewModel(forItem item: ListItem) -> FeedChartViewModel {
    return FeedChartViewModel(account: self.account, api: self.api, feedId: item.feedId)
  }

}
