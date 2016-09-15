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

struct FeedListSection: SectionModelType {
  private(set) var header: String
  private(set) var items: [FeedViewModel]

  init(header: String, items: [FeedViewModel]) {
    self.header = header
    self.items = items
  }

  typealias Item = FeedViewModel
  init(original: FeedListSection, items: [FeedViewModel]) {
    self = original
    self.items = items
  }
}

class FeedListViewModel {

  private let account: Account
  private let api: EmonCMSAPI

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
  }

  func fetch() -> Observable<[FeedListSection]> {
    return self.api.feedList(account)
      .map{ [weak self] feeds -> [FeedListSection] in
        guard let strongSelf = self else { return [] }

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

        var sections: [FeedListSection] = []
        for section in sectionBuilder.keys.sorted(by: <) {
          let sortedSectionFeeds = sectionBuilder[section]!
            .sorted(by: { $0.name < $1.name })
            .map { FeedViewModel(account: strongSelf.account, api: strongSelf.api, feed: $0) }
          sections.append(FeedListSection(header: section, items: sortedSectionFeeds))
        }

        return sections
      }
  }

}
