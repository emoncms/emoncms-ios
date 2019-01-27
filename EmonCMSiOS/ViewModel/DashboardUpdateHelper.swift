//
//  DashboardUpdateHelper.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

final class DashboardUpdateHelper {

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let scheduler: SerialDispatchQueueScheduler

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "org.openenergymonitor.emoncms.DashboardUpdateHelper")
  }

  func updateDashboards() -> Observable<()> {
    return Observable.deferred {
      return self.api.dashboardList(self.account.credentials)
        .observeOn(self.scheduler)
        .flatMap { [weak self] dashboards -> Observable<()> in
          guard let self = self else { return Observable.empty() }
          let realm = self.realmController.createAccountRealm(forAccountId: self.account.uuid)
          return self.saveDashboards(dashboards, inRealm: realm)
        }
        .observeOn(MainScheduler.asyncInstance)
    }
  }

  private func saveDashboards(_ dashboards: [Dashboard], inRealm realm: Realm) -> Observable<()> {
    return Observable.create() { observer in
      do {
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

        try realm.write {
          realm.delete(existingDashboards)
          realm.add(dashboards, update: true)
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
