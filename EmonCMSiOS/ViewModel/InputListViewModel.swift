//
//  InputListViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 23/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

final class InputListViewModel {
  struct ListItem {
    let inputId: String
    let name: String
    let desc: String
    let time: Date
    let value: String
  }

  typealias Section = SectionModel<String, ListItem>

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm
  private let inputUpdateHelper: InputUpdateHelper

  private var cancellables = Set<AnyCancellable>()

  // Inputs
  @Published var active = false
  let refresh = PassthroughSubject<Void, Never>()

  // Outputs
  @Published private(set) var inputs: [Section] = []
  @Published private(set) var updateTime: Date? = nil
  let isRefreshing: AnyPublisher<Bool, Never>
  @Published private(set) var serverNeedsUpdate = false

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createAccountRealm(forAccountId: account.uuid)
    self.inputUpdateHelper = InputUpdateHelper(realmController: realmController, account: account, api: api)

    let isRefreshingIndicator = ActivityIndicatorCombine()
    self.isRefreshing = isRefreshingIndicator.asPublisher()

    let inputsQuery = self.realm.objects(Input.self)
      .sorted(by: [SortDescriptor(keyPath: #keyPath(Input.nodeid)), SortDescriptor(keyPath: #keyPath(Input.name))])
    inputsQuery.collectionPublisher
      .map(self.inputsToSections)
      .sink(
        receiveCompletion: { error in
          AppLog.error("Query errored when it shouldn't! \(error)")
        },
        receiveValue: { [weak self] items in
          guard let self = self else { return }
          self.inputs = items
          self.updateTime = Date()
        })
      .store(in: &self.cancellables)

    let becameActive = $active
      .filter { $0 == true }
      .removeDuplicates()
      .becomeVoid()

    Publishers.Merge(self.refresh, becameActive)
      .map { [weak self] () -> AnyPublisher<Void, Never> in
        guard let self = self else { return Empty().eraseToAnyPublisher() }
        return self.inputUpdateHelper.updateInputs()
          .catch { [weak self] error -> AnyPublisher<Void, Never> in
            if error == EmonCMSAPI.APIError.invalidResponse {
              self?.serverNeedsUpdate = true
            }
            return Just(()).eraseToAnyPublisher()
          }
          .trackActivity(isRefreshingIndicator)
          .eraseToAnyPublisher()
      }
      .switchToLatest()
      .sink(receiveValue: { _ in })
      .store(in: &self.cancellables)
  }

  private func inputsToSections(_ inputs: Results<Input>) -> [Section] {
    var sectionBuilder: [String: [Input]] = [:]
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
          ListItem(inputId: input.id, name: input.name, desc: input.desc, time: input.time,
                   value: input.value.prettyFormat())
        }
      sections.append(Section(model: section, items: items))
    }

    return sections
  }
}
