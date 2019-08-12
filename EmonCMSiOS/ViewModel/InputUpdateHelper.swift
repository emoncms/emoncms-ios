//
//  InputUpdateHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import RealmSwift

final class InputUpdateHelper {

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let scheduler: DispatchQueue

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.scheduler = DispatchQueue(label: "org.openenergymonitor.emoncms.InputUpdateHelper")
  }

  func updateInputs() -> AnyPublisher<Void, EmonCMSAPI.APIError> {
    return Deferred {
      return self.api.inputList(self.account.credentials)
        .receive(on: self.scheduler)
        .flatMap { [weak self] inputs -> AnyPublisher<Void, EmonCMSAPI.APIError> in
          guard let self = self else { return Empty().eraseToAnyPublisher() }
          let realm = self.realmController.createAccountRealm(forAccountId: self.account.uuid)
          return self.saveInputs(inputs, inRealm: realm).eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
    }.eraseToAnyPublisher()
  }

  private func saveInputs(_ inputs: [Input], inRealm realm: Realm) -> AnyPublisher<Void, EmonCMSAPI.APIError> {
    return Deferred<Just<Void>> {
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

      do {
        try realm.write {
          realm.delete(existingInputs)
          realm.add(inputs, update: .all)
        }
      } catch {
        AppLog.error("Failed to write to Realm: \(error)")
      }

      return Just(())
    }
    .setFailureType(to: EmonCMSAPI.APIError.self)
    .eraseToAnyPublisher()
  }

}
