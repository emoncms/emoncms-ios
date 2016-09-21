//
//  FeedChartViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RealmSwift

class FeedChartViewModel {

  private let account: Account
  private let api: EmonCMSAPI
  private let realm: Realm
  private let chart: Chart

  // Inputs
  let active = Variable<Bool>(false)
  let name: Variable<String>
  let dateRange: Variable<DateRange>
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var dataPoints: Driver<[DataPoint]>
  private(set) var isRefreshing: Driver<Bool>

  private init(account: Account, api: EmonCMSAPI, realm: Realm, chart: Chart) {
    self.account = account
    self.api = api
    self.realm = realm
    self.chart = chart

    self.name = Variable<String>(chart.name)
    self.dateRange = Variable<DateRange>(chart.dateRange)

    self.dataPoints = Driver.empty()

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    let becameActive = self.active.asObservable()
      .filter { $0 == true }
      .distinctUntilChanged()
      .becomeVoid()

    let refreshSignal = Observable.of(self.refresh, becameActive)
      .merge()

    let dateRange = self.dateRange.asObservable()

    self.dataPoints = Observable.combineLatest(refreshSignal, dateRange) { $1 }
      .flatMapLatest { [weak self] dateRange -> Observable<[DataPoint]> in
        guard let strongSelf = self else { return Observable.empty() }

        guard let feedId = strongSelf.chart.dataSets[0].feed?.id else { return Observable.empty() }

        let (startDate, endDate) = dateRange.calculateDates()
        let interval = Int(endDate.timeIntervalSince(startDate) / 500)
        return strongSelf.api.feedData(strongSelf.account, id: feedId, at: startDate, until: endDate, interval: interval)
          .catchErrorJustReturn([])
          .trackActivity(isRefreshing)
      }
      .asDriver(onErrorJustReturn: [])
  }

  convenience init?(account: Account, api: EmonCMSAPI, chartId: String) {
    let realm = account.createRealm()
    guard let chart = realm.object(ofType: Chart.self, forPrimaryKey: chartId) else {
      return nil
    }
    self.init(account: account, api: api, realm: realm, chart: chart)
  }

  convenience init?(account: Account, api: EmonCMSAPI, feedId: String) {
    let realm = account.createRealm()
    guard let feed = realm.object(ofType: Feed.self, forPrimaryKey: feedId) else {
      return nil
    }

    let chart = Chart()
    chart.name = feed.name
    let dataSet = ChartDataSet()
    dataSet.feed = feed
    chart.dataSets.append(dataSet)

    self.init(account: account, api: api, realm: realm, chart: chart)
  }

  func save() -> Observable<()> {
    let realm = self.realm
    let chart = self.chart
    return Observable.create({ observer in
      do {
        try realm.write {
          realm.add(chart, update: true)
        }
        observer.onNext(())
        observer.onCompleted()
      } catch {
        observer.onError(error)
      }

      return Disposables.create()
    })
  }

}
