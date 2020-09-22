//
//  FeedViewModel.swift
//  EmonCMSiOSWidgetExtension
//
//  Created by Matt Galloway on 21/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

final class FeedViewModel {
  enum FeedViewModelError: Error {
    case unknown
    case invalidFeed
    case keychainLocked
    case cancelled
    case fetchFailed
  }

  private let realmController: RealmController
  private let keychainController: KeychainController
  private let api: EmonCMSAPI

  private var cancellables: Set<AnyCancellable> = []

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
  }

  func fetchData(
    accountId: String,
    feedId: String,
    completion: @escaping (FeedWidgetItem?, FeedViewModelError?) -> Void) {
    self.fetchData(for: [(accountId: accountId, feedId: feedId)]) { items, error in
      completion(items.first, error)
    }
  }

  func fetchData(
    for feeds: [(accountId: String, feedId: String)],
    completion: @escaping ([FeedWidgetItem], FeedViewModelError?) -> Void) {
    var items: [FeedWidgetItem] = []
    feeds
      .map { (accountId: String, feedId: String) in
        fetchDataImpl(accountId: accountId, feedId: feedId)
      }
      .publisher
      .flatMap { $0 }
      .collect()
      .sink { result in
        switch result {
        case .finished:
          completion(items, nil)
        case .failure(let error):
          completion([], error)
        }
      } receiveValue: { items = $0 }
      .store(in: &self.cancellables)
  }

  private func fetchDataImpl(accountId: String, feedId: String) -> AnyPublisher<FeedWidgetItem, FeedViewModelError> {
    let apiKey: String
    do {
      apiKey = try self.keychainController.apiKey(forAccountWithId: accountId)
    } catch KeychainController.KeychainControllerError.keychainFailed {
      return Fail(error: FeedViewModelError.keychainLocked).eraseToAnyPublisher()
    } catch {
      return Fail(error: FeedViewModelError.unknown).eraseToAnyPublisher()
    }

    let realm = self.realmController.createMainRealm()

    guard let account = realm.object(ofType: Account.self, forPrimaryKey: accountId) else {
      return Fail(error: FeedViewModelError.invalidFeed).eraseToAnyPublisher()
    }

    let accountName = account.name
    let accountCredentials = AccountCredentials(url: account.url, apiKey: apiKey)
    let accountRealm = self.realmController.createAccountRealm(forAccountId: accountId)

    guard let feed = accountRealm.object(ofType: Feed.self, forPrimaryKey: feedId) else {
      return Fail(error: FeedViewModelError.invalidFeed).eraseToAnyPublisher()
    }

    let feedName = feed.name

    let range = 3600
    let endDate = Date()
    let startDate = endDate.addingTimeInterval(TimeInterval(-range))
    return self.api.feedData(accountCredentials, id: feedId, at: startDate, until: endDate, interval: range / 200)
      .map { dataPoints -> FeedWidgetItem in
        FeedWidgetItem(
          accountId: accountId,
          accountName: accountName,
          feedId: feedId,
          feedName: feedName,
          feedChartData: dataPoints)
      }
      .mapError { _ in FeedViewModelError.fetchFailed }
      .eraseToAnyPublisher()
  }
}
