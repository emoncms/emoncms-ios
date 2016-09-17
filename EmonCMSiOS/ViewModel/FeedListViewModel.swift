//
//  FeedListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxDataSources
import Realm
import RealmSwift
import RxRealm

class FeedListViewModel {

  struct Section: SectionModelType {
    private(set) var header: String
    private(set) var items: [FeedViewModel]

    init(header: String, items: [FeedViewModel]) {
      self.header = header
      self.items = items
    }

    typealias Item = FeedViewModel
    init(original: Section, items: [FeedViewModel]) {
      self = original
      self.items = items
    }
  }

  private let account: Account
  private let api: EmonCMSAPI
  private let realm: Realm

  private let disposeBag = DisposeBag()

  let feeds = Variable<[Section]>([])

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()

    self.realm.objects(Feed.self)
      .asObservableArray()
      .map(self.feedsToSections)
      .bindTo(self.feeds)
      .addDisposableTo(self.disposeBag)
  }

  func update() -> Observable<()> {
    return self.api.feedList(account)
      .becomeVoidAndIgnoreElements()
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
    for section in sectionBuilder.keys.sorted(by: <) {
      let sortedSectionFeeds = sectionBuilder[section]!
        .sorted(by: { $0.name < $1.name })
        .map { FeedViewModel(account: self.account, api: self.api, feed: $0) }
      sections.append(Section(header: section, items: sortedSectionFeeds))
    }

    return sections
  }

}
