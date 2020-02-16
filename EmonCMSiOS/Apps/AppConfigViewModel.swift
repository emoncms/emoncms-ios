//
//  AppConfigViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import RealmSwift

final class AppConfigViewModel {
  enum SaveError: Error {
    case generic
    case realmFailure(Error)
    case missingFields([AppConfigField])
  }

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let appData: AppData
  private let appCategory: AppCategory

  lazy var feedListHelper: FeedListHelper = {
    FeedListHelper(realmController: self.realmController, account: self.account, api: self.api)
  }()

  init(
    realmController: RealmController,
    account: AccountController,
    api: EmonCMSAPI,
    appDataId: String?,
    appCategory: AppCategory) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    if let appDataId = appDataId {
      self.appData = self.realm.object(ofType: AppData.self, forPrimaryKey: appDataId)!
    } else {
      self.appData = AppData()
      self.appData.appCategory = appCategory
      self.appData.name = appCategory.displayName
    }
    self.appCategory = appCategory
  }

  static let nameConfigFieldID = "name"

  func configFields() -> [AppConfigField] {
    var fields = [AppConfigField]()

    // Always have a name
    fields.append(AppConfigFieldString(id: AppConfigViewModel.nameConfigFieldID, name: "Name", optional: false))
    fields.append(contentsOf: self.appCategory.feedConfigFields)

    return fields
  }

  func configData() -> [String: Any] {
    var data: [String: Any] = [:]

    data[AppConfigViewModel.nameConfigFieldID] = self.appData.name
    for feedConfigField in self.appCategory.feedConfigFields {
      if let feedId = self.appData.feed(forName: feedConfigField.id) {
        data[feedConfigField.id] = feedId
      }
    }

    return data
  }

  func updateWithConfigData(_ data: [String: Any]) -> AnyPublisher<AppUUIDAndCategory, SaveError> {
    return Future<AppUUIDAndCategory, SaveError> { [weak self] result in
      guard let self = self else { result(.failure(.generic)); return }

      // Validate first
      var missingFields: [AppConfigField] = []
      for field in self.configFields() where field.optional == false {
        if data[field.id] == nil {
          missingFields.append(field)
        }
      }

      if missingFields.count > 0 {
        result(.failure(.missingFields(missingFields)))
      } else {
        do {
          let appData = self.appData
          try self.realm.write {
            if let name = data[AppConfigViewModel.nameConfigFieldID] as? String {
              appData.name = name
            }
            for feedConfigField in self.appCategory.feedConfigFields {
              if let feedId = data[feedConfigField.id] as? String {
                appData.setFeed(feedId, forName: feedConfigField.id)
              }
            }

            if appData.realm == nil {
              self.realm.add(appData)
            }
          }
          result(.success((self.appData.uuid, self.appData.appCategory)))
        } catch {
          result(.failure(.realmFailure(error)))
        }
      }
    }.eraseToAnyPublisher()
  }

  func feedListViewModel() -> FeedListViewModel {
    return FeedListViewModel(realmController: self.realmController, account: self.account, api: self.api)
  }
}
