//
//  FeedListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import Realm
import RealmSwift

final class FeedListViewModel {

  struct ListItem {
    let feedId: String
    let name: String
    let time: Date
    let value: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let feedUpdateHelper: FeedUpdateHelper

  private var cancellables = Set<AnyCancellable>()

  // Inputs
  @Published var active = false
  let refresh = PassthroughSubject<Void, Never>()
  @Published var searchTerm = ""

  // Outputs
  @Published private(set) var feeds: [Section] = []
  @Published private(set) var updateTime: Date? = nil
  let isRefreshing: AnyPublisher<Bool, Never>

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.feedUpdateHelper = FeedUpdateHelper(realmController: realmController, account: account, api: api)

    let isRefreshingIndicator = ActivityIndicatorCombine()
    self.isRefreshing = isRefreshingIndicator.asPublisher()

    $searchTerm
      .removeDuplicates()
      .map { searchTerm -> AnyPublisher<[Feed], Never> in
        var results = self.realm.objects(Feed.self)
        let trimmedSearchTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSearchTerm != "" {
          results = results.filter("name CONTAINS[c] %@", trimmedSearchTerm)
        }
        results = results.sorted(byKeyPath: #keyPath(Feed.name))
        return Publishers.array(from: results)
          .catch { error -> AnyPublisher<[Feed], Never> in
            AppLog.error("Query errored when it shouldn't! \(error)")
            return Just<[Feed]>([]).eraseToAnyPublisher()
          }
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .map(self.feedsToSections)
      .sink(
        receiveValue: { [weak self] items in
          guard let self = self else { return }
          self.feeds = items
          self.updateTime = Date()
        })
      .store(in: &self.cancellables)

    let becameActive = $active
      .filter { $0 == true }
      .removeDuplicates()
      .becomeVoid()

    Publishers.Merge(self.refresh, becameActive)
      .map { [weak self] () -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty().eraseToAnyPublisher() }
        return self.feedUpdateHelper.updateFeeds()
          .replaceError(with: ())
          .trackActivity(isRefreshingIndicator)
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .sink(receiveValue: { _ in })
      .store(in: &self.cancellables)
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
