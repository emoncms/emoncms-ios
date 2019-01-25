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
    case httpsRequired
    case networkFailed
    case invalidCredentials
  }

  private let realmController: RealmController
  private let keychainController: KeychainController
  private let api: EmonCMSAPI

  let name = BehaviorRelay<String>(value: "")
  let url = BehaviorRelay<String>(value: "")
  let username = BehaviorRelay<String>(value: "")
  let password = BehaviorRelay<String>(value: "")
  let apiKey = BehaviorRelay<String>(value: "")

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
  }

  func canSave() -> Observable<Bool> {
    return Observable
      .combineLatest(self.name.asObservable(),
                     self.url.asObservable(),
                     self.username.asObservable(),
                     self.password.asObservable(),
                     self.apiKey.asObservable())
      { name, url, username, password, apiKey in
        if name.isEmpty || url.isEmpty {
          return false
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

  func validate() -> Observable<AccountCredentials> {
    let url = self.url.value
    let username = self.username.value
    let password = self.password.value
    let apiKey = self.apiKey.value

    let loginObservable: Observable<AccountCredentials>

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

  func saveAccount(withUrl url: String, apiKey: String) -> Observable<String> {
    return Observable.create { observer -> Disposable in
      let realm = self.realmController.createRealm()

      let account = Account()
      account.name = self.name.value
      account.url = url

      do {
        try self.keychainController.saveAccount(forId: account.uuid, apiKey: apiKey)
        try realm.write {
          realm.add(account)
        }
        observer.onNext(account.uuid)
        observer.onCompleted()
      } catch {
        observer.onError(error)
      }

      return Disposables.create()
    }
  }

}
