//
//  InputListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import Realm
import RealmSwift
import RxRealm

final class InputListViewModel {

  struct ListItem {
    let inputId: String
    let name: String
    let desc: String
    let time: Date
    let value: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let inputUpdateHelper: InputUpdateHelper

  private let disposeBag = DisposeBag()

  // Inputs
  let active = BehaviorRelay<Bool>(value: false)
  let refresh = ReplaySubject<()>.create(bufferSize: 1)

  // Outputs
  private(set) var inputs: Driver<[Section]>
  private(set) var updateTime: Driver<Date?>
  private(set) var isRefreshing: Driver<Bool>
  lazy var serverNeedsUpdate: Driver<Bool> = {
    return self.serverNeedsUpdateSubject.asDriver(onErrorJustReturn: true).distinctUntilChanged()
  }()
  private var serverNeedsUpdateSubject = ReplaySubject<Bool>.create(bufferSize: 1)

  init(account: AccountController, api: EmonCMSAPI) {
    self.account = account
    self.api = api
    self.realm = account.createRealm()
    self.inputUpdateHelper = InputUpdateHelper(account: account, api: api)

    self.inputs = Driver.never()
    self.updateTime = Driver.never()
    self.isRefreshing = Driver.never()

    let inputsQuery = self.realm.objects(Input.self)
      .sorted(by: [SortDescriptor(keyPath: #keyPath(Input.nodeid)), SortDescriptor(keyPath: #keyPath(Input.name))])
    self.inputs = Observable.array(from: inputsQuery)
      .map(self.inputsToSections)
      .asDriver(onErrorJustReturn: [])

    self.updateTime = self.inputs
      .map { _ in Date() }
      .startWith(nil)
      .asDriver(onErrorJustReturn: Date())

    let isRefreshing = ActivityIndicator()
    self.isRefreshing = isRefreshing.asDriver()

    let becameActive = self.active.asObservable()
      .distinctUntilChanged()
      .filter { $0 == true }
      .becomeVoid()

    Observable.of(self.refresh, becameActive)
      .merge()
      .flatMapLatest { [weak self] () -> Observable<()> in
        guard let self = self else { return Observable.empty() }
        return self.inputUpdateHelper.updateInputs()
          .catchError { [weak self] error in
            if error == EmonCMSAPI.APIError.invalidResponse {
              self?.serverNeedsUpdateSubject.onNext(true)
            }
            throw error
          }
          .catchErrorJustReturn(())
          .trackActivity(isRefreshing)
      }
      .subscribe()
      .disposed(by: self.disposeBag)

    self.serverNeedsUpdateSubject.onNext(false)
  }

  private func inputsToSections(_ inputs: [Input]) -> [Section] {
    var sectionBuilder: [String:[Input]] = [:]
    for input in inputs {
      let sectionInputs: [Input]
      if let existingInputs = sectionBuilder[input.nodeid] {
        sectionInputs = existingInputs
      } else {
        sectionInputs = []
      }
      sectionBuilder[input.nodeid] = sectionInputs + [input]
    }

    var sections: [Section] = []
    for section in sectionBuilder.keys.sorted() {
      let items = sectionBuilder[section]!
        .map { input in
          return ListItem(inputId: input.id, name: input.name, desc: input.desc, time: input.time, value: input.value.prettyFormat())
        }
      sections.append(Section(model: section, items: items))
    }

    return sections
  }

}
