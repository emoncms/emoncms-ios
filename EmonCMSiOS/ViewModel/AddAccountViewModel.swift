//
//  AddAccountViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
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

  let name = BehaviorRelay<String>(value: "")
  let url = BehaviorRelay<String>(value: SharedConstants.EmonCMSdotOrgURL)
  let username = BehaviorRelay<String>(value: "")
  let password = BehaviorRelay<String>(value: "")
  let apiKey = BehaviorRelay<String>(value: "")

  init(realmController: RealmController, api: EmonCMSAPI, accountId: String? = nil) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
    self.realm = realmController.createMainRealm()
    if let accountId = accountId {
      let account = self.realm.object(ofType: Account.self, forPrimaryKey: accountId)!
      self.account = account
      self.name.accept(account.name)
      self.url.accept(account.url)
      if let apiKey = self.keychainController.apiKey(forAccountWithId: account.uuid) {
        self.apiKey.accept(apiKey)
      }
    } else {
      self.account = nil
    }
  }

  func canSave() -> Observable<Bool> {
    return Observable
      .combineLatest(self.name.asObservable(),
                     self.url.asObservable(),
                     self.username.asObservable(),
                     self.password.asObservable(),
                     self.apiKey.asObservable())
      { [weak self] name, url, username, password, apiKey in
        guard let self = self else { return false }

        if name.isEmpty || url.isEmpty {
          return false
        }

        if self.account != nil {
          return true
        }

        if !username.isEmpty && !password.isEmpty {
          return true
        } else if !apiKey.isEmpty {
          return true
        }

        return false
      }
      .distinctUntilChanged()
  }

  private func validate(name: String, url: String, username: String, password: String, apiKey: String) -> Observable<AccountCredentials?> {
    if self.account != nil {
      return Observable.just(nil)
    }

    let loginObservable: Observable<AccountCredentials?>

    if !apiKey.isEmpty {
      let accountCredentials = AccountCredentials(url: url, apiKey: apiKey)
      loginObservable = self.api.feedList(accountCredentials)
        .map { _ in
          return accountCredentials
      }
    } else {
      loginObservable = self.api.userAuth(url: url, username: username, password: password)
        .map { apiKey in
          return AccountCredentials(url: url, apiKey: apiKey)
      }
    }

    return loginObservable
      .catchError { error in
        let returnError: AddAccountError
        if let error = error as? EmonCMSAPI.APIError {
          switch error {
          case .invalidCredentials:
            returnError = .invalidCredentials
          case .atsFailed:
            returnError = .httpsRequired
          default:
            returnError = .networkFailed
          }
        } else {
          returnError = .networkFailed
        }

        return Observable.error(returnError)
    }
  }

  func saveAccount() -> Observable<String> {
    guard let _ = URL(string: self.url.value) else { return Observable.error(AddAccountError.urlNotValid) }

    let name = self.name.value
    let url = self.url.value
    let username = self.username.value
    let password = self.password.value
    let apiKey = self.apiKey.value

    return self.validate(name: name, url: url, username: username, password: password, apiKey: apiKey)
      .observeOn(MainScheduler.asyncInstance)
      .map { [weak self] credentials in
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
  }

}
