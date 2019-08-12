//
//  DashboardUpdateHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import RealmSwift

final class DashboardUpdateHelper {

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let scheduler: DispatchQueue

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.scheduler = DispatchQueue(label: "org.openenergymonitor.emoncms.DashboardUpdateHelper")
  }

  func updateDashboards() -> AnyPublisher<Void, EmonCMSAPI.APIError> {
    return Deferred {
      return self.api.dashboardList(self.account.credentials)
        .receive(on: self.scheduler)
        .flatMap { [weak self] dashboards -> AnyPublisher<Void, EmonCMSAPI.APIError> in
          guard let self = self else { return Empty().eraseToAnyPublisher() }
          let realm = self.realmController.createAccountRealm(forAccountId: self.account.uuid)
          return self.saveDashboards(dashboards, inRealm: realm).eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
    }.eraseToAnyPublisher()
  }

  private func saveDashboards(_ dashboards: [Dashboard], inRealm realm: Realm) -> AnyPublisher<Void, EmonCMSAPI.APIError> {
    return Deferred<Just<Void>> {
      let existingDashboards = realm.objects(Dashboard.self).filter {
        var inNewArray = false
        for dashboard in dashboards {
          if dashboard.id == $0.id {
            inNewArray = true
            break
          }
        }
        return !inNewArray
      }

      do {
        try realm.write {
          realm.delete(existingDashboards)
          realm.add(dashboards, update: .all)
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
