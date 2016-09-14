//
//  FeedListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

class FeedListViewModel {

  private let api: EmonCMSAPI

  private struct Section {
    let name: String
    let feeds: [Feed]
  }
  private var sections: [Section] = []

  init(api: EmonCMSAPI) {
    self.api = api
  }

  var numberOfSections: Int {
    return self.sections.count
  }

  func numberOfFeeds(inSection section: Int) -> Int {
    let section = self.sections[section]
    return section.feeds.count
  }

  func feedViewModel(atIndexPath indexPath: IndexPath) -> FeedViewModel {
    let section = self.sections[indexPath.section]
    let feed = section.feeds[indexPath.row]
    return FeedViewModel(api: self.api, feed: feed)
  }

  func titleForSection(atIndex index: Int) -> String {
    let section = self.sections[index]
    return section.name
  }

  func update() -> Observable<Void> {
    return self.api.feedList()
      .map{ [weak self] feeds in
        guard let strongSelf = self else { return }

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
          let sortedSectionFeeds = sectionBuilder[section]!.sorted(by: { $0.name < $1.name })
          sections.append(Section(name: section, feeds: sortedSectionFeeds))
        }

        strongSelf.sections = sections
      }
      .ignoreElements()
  }

}
