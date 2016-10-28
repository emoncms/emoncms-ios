//
//  FeedListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import RxRealm

final class ChartListViewModel {

  struct ListItem {
    let chartId: String
    let name: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let account: Account
  private let api: EmonCMSAPI
  private let realm: Realm

  private let disposeBag = DisposeBag()

  // Inputs

  // Outputs
  private(set) var charts: Driver<[ListItem]>

  init(account: Account, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()

    self.charts = Driver.never()

    self.charts = Observable.arrayFrom(self.realm.objects(Chart.self))
      .map {
        $0.map { ListItem(chartId: $0.uuid, name: $0.name) }
      }
      .asDriver(onErrorJustReturn: [])
  }

  func feedChartViewModel(forItem item: ListItem) -> FeedChartViewModel {
    return FeedChartViewModel(account: self.account, api: self.api, chartId: item.chartId)!
  }

  func deleteChart(withId id: String) -> Observable<()> {
    let realm = self.realm
    return Observable.create() { observer in
      do {
        if let chart = realm.object(ofType: Chart.self, forPrimaryKey: id) {
          try realm.write {
            realm.delete(chart)
          }
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
