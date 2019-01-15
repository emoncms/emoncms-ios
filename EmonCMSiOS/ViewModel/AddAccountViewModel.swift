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
  let apikey = BehaviorRelay<String>(value: "")

  init(realmController: RealmController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.keychainController = KeychainController()
    self.api = api
  }

  func canSave() -> Observable<Bool> {
    return Observable
      .combineLatest(self.name.asObservable(), self.url.asObservable(), self.apikey.asObservable()) { name, url, apikey in
        return !name.isEmpty && !url.isEmpty && !apikey.isEmpty
      }
      .distinctUntilChanged()
  }

  func validate() -> Observable<(url: String, apiKey: String)> {
    // TODO: Shouldn't have to create an `AccoutRealmController` here
    let account = AccountController(uuid: UUID().uuidString, url: self.url.value, apikey: self.apikey.value)
    let accountDetails = (self.url.value, self.apikey.value)
    return self.api.feedList(account)
      .catchError { error -> Observable<[Feed]> in
        let returnError: AddAccountError
        if let error = error as? EmonCMSAPI.EmonCMSAPIError {
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
      .map { _ in
        return accountDetails
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
