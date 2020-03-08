//
//  AddAccountViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

final class AddAccountViewModel {
  enum AddAccountError: Error {
    case urlNotValid
    case httpsRequired
    case networkFailed
    case invalidCredentials
    case saveFailed
  }

  private let realmController: RealmController
  private let keychainController: KeychainController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let account: Account?

  @Published var name = ""
  @Published var url = SharedConstants.EmonCMSdotOrgURL
  @Published var username = ""
  @Published var password = ""
  @Published var apiKey = ""

  init(realmController: RealmController, api: EmonCMSAPI, accountId: String? = nil) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createMainRealm()
    if let accountId = accountId {
      let account = self.realm.object(ofType: Account.self, forPrimaryKey: accountId)!
      self.account = account
      self.name = account.name
      self.url = account.url
      if let apiKey = try? self.keychainController.apiKey(forAccountWithId: account.uuid) {
        self.apiKey = apiKey
      }
    } else {
      self.account = nil
    }
  }

  func canSave() -> AnyPublisher<Bool, Never> {
    return Publishers
      .CombineLatest4($name, $url, $username, $password)
      .combineLatest($apiKey) { [weak self] first, apiKey in
        let (name, url, username, password) = first
        guard let self = self else { return false }

        if name.isEmpty || url.isEmpty {
          return false
        }

        if self.account != nil {
          return true
        }

        if !username.isEmpty, !password.isEmpty {
          return true
        } else if !apiKey.isEmpty {
          return true
        }

        return false
      }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  private func validate(name: String, url: String, username: String, password: String,
                        apiKey: String) -> AnyPublisher<AccountCredentials?, AddAccountError> {
    if self.account != nil {
      return Just(nil).setFailureType(to: AddAccountError.self).eraseToAnyPublisher()
    }

    let loginObservable: AnyPublisher<AccountCredentials?, EmonCMSAPI.APIError>

    if !apiKey.isEmpty {
      let accountCredentials = AccountCredentials(url: url, apiKey: apiKey)
      loginObservable = self.api.feedList(accountCredentials)
        .map { _ in
          accountCredentials
        }
        .eraseToAnyPublisher()
    } else {
      loginObservable = self.api.userAuth(url: url, username: username, password: password)
        .map { apiKey in
          AccountCredentials(url: url, apiKey: apiKey)
        }
        .eraseToAnyPublisher()
    }

    return loginObservable
      .mapError { error in
        let returnError: AddAccountError
        switch error {
        case .invalidCredentials:
          returnError = .invalidCredentials
        case .atsFailed:
          returnError = .httpsRequired
        default:
          returnError = .networkFailed
        }

        return returnError
      }
      .eraseToAnyPublisher()
  }

  func saveAccount() -> AnyPublisher<String, AddAccountError> {
    guard let _ = URL(string: self.url) else { return Fail(error: AddAccountError.urlNotValid).eraseToAnyPublisher() }

    let name = self.name
    let url = self.url
    let username = self.username
    let password = self.password
    let apiKey = self.apiKey

    return self.validate(name: name, url: url, username: username, password: password, apiKey: apiKey)
      .tryMap { [weak self] credentials in
        guard let self = self else { throw AddAccountError.saveFailed }

        let account = self.account ?? Account()

        do {
          if let credentials = credentials {
            try self.keychainController.saveAccount(forId: account.uuid, apiKey: credentials.apiKey)
          }

          try self.realm.write {
            account.name = name
            account.url = url
            if account.realm == nil {
              self.realm.add(account)
            }
          }
        } catch {
          throw AddAccountError.saveFailed
        }

        return account.uuid
      }
      .mapError { error in
        if let error = error as? AddAccountError {
          return error
        }
        return .saveFailed
      }
      .eraseToAnyPublisher()
  }
}
