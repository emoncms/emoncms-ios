//
//  InputUpdateHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class InputUpdateHelper {

  private let account: AccountRealmController
  private let api: EmonCMSAPI
  private let scheduler: SerialDispatchQueueScheduler

  init(account: AccountRealmController, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "org.openenergymonitor.emoncms.InputUpdateHelper")
  }

  func updateInputs() -> Observable<()> {
    return Observable.deferred {
      return self.api.inputList(self.account)
        .observeOn(self.scheduler)
        .flatMap { inputs -> Observable<()> in
          let realm = self.account.createRealm()
          return self.saveInputs(inputs, inRealm: realm)
        }
        .observeOn(MainScheduler.asyncInstance)
    }
  }

  private func saveInputs(_ inputs: [Input], inRealm realm: Realm) -> Observable<()> {
    return Observable.create() { observer in
      do {
        let existingInputs = realm.objects(Input.self).filter {
          var inNewArray = false
          for input in inputs {
            if input.id == $0.id {
              inNewArray = true
              break
            }
          }
          return !inNewArray
        }

        try realm.write {
          realm.delete(existingInputs)
          realm.add(inputs, update: true)
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
