//
//  ComplicationViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 25/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation
import ClockKit
import WatchKit

import RxSwift
import RxCocoa
import RealmSwift
import RxRealm

class ComplicationViewModel {

  struct FeedData {
    let name: String
    let value: String
  }

  let feedId = Variable<String?>(nil)

  private let loginController: LoginController
  private var realm: Realm?

  private(set) var currentFeedData: FeedData?

  private let disposeBag = DisposeBag()

  init(loginController: LoginController) {
    self.loginController = loginController
    self.setupBindings()
  }

  private func setupBindings() {
    if let feedId = UserDefaults.standard.string(forKey: SharedConstants.UserDefaultsKeys.complicationFeedId.rawValue) {
      self.feedId.value = feedId
    }

    self.feedId
      .asObservable()
      .subscribe(onNext: { feedId in
        if let feedId = feedId {
          UserDefaults.standard.set(feedId, forKey: SharedConstants.UserDefaultsKeys.complicationFeedId.rawValue)
        } else {
          UserDefaults.standard.removeObject(forKey: SharedConstants.UserDefaultsKeys.complicationFeedId.rawValue)
        }
      })
      .addDisposableTo(self.disposeBag)

    let accountAndFeedId = Observable
      .combineLatest(self.loginController.account, self.feedId.asObservable()) { ($0, $1) }
      .shareReplay(1)

    accountAndFeedId
      .flatMapLatest { account, feedId -> Observable<FeedData> in
        if let account = account, let feedId = feedId {
          let realm = account.createRealm()
          if let feed = realm.object(ofType: Feed.self, forPrimaryKey: feedId) {
            let nameSignal = feed.rx.observe(String.self, "name").map { $0 ?? "" }
            let valueSignal = feed.rx.observe(Double.self, "value").map { $0 ?? 0 }
            return Observable.combineLatest(nameSignal, valueSignal) {
              FeedData(name: $0, value: $1.prettyFormat())
            }
          }
        }

        return Observable.never()
      }
      .subscribe(onNext: { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.currentFeedData = $0
      })
      .addDisposableTo(self.disposeBag)

    accountAndFeedId
      .skip(1)
      .subscribe(onNext: { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.scheduleBackgroundUpdate()
      })
      .addDisposableTo(self.disposeBag)
  }

  static func placeholderFeedData() -> FeedData {
    return FeedData(name: "use", value: "892")
  }

  private func scheduleBackgroundUpdate() {
    WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(), userInfo: nil) { _ in () }
  }

}
