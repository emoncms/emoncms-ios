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

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let scheduler: SerialDispatchQueueScheduler

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "org.openenergymonitor.emoncms.InputUpdateHelper")
  }

  func updateInputs() -> Observable<()> {
    return Observable.deferred {
      return self.api.inputList(self.account.credentials)
        .observeOn(self.scheduler)
        .flatMap { [weak self] inputs -> Observable<()> in
          guard let self = self else { return Observable.empty() }
          let realm = self.realmController.createAccountRealm(forAccountId: self.account.uuid)
          return self.saveInputs(inputs, inRealm: realm)
        }
        .observeOn(MainScheduler.asyncInstance)
    }
  }

  private func saveInputs(_ inputs: [Input], inRealm realm: Realm) -> Observable<()> {
    return Observable.deferred {
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
        realm.add(inputs, update: .all)
      }

      return Observable.just(())
    }
  }

}
