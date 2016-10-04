//
//  BackendController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 04/10/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RealmSwift

final class BackendController {

  private let api: EmonCMSAPI

  init(api: EmonCMSAPI) {
    self.api = api
  }

  func updateFeedList(account: Account) -> Observable<()> {
    let realm = account.createRealm()
    return self.api.feedList(account)
      .flatMap { self.saveRealmObjects(realm: realm, objects: $0) }
  }

  private func saveRealmObjects(realm: Realm, objects: [Object]) -> Observable<()> {
    return Observable.create() { observer in
      do {
        try realm.write {
          realm.add(objects, update: true)
        }
        observer.onNext(())
        observer.onCompleted()
      } catch {
        observer.onError(error)
      }

      return Disposables.create()
    }
  }

}
