//
//  AccountViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 28/04/2022.
//  Copyright © 2022 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Realm
import RealmSwift

final class AccountViewModel {
  enum AccountViewModelError: Error {
    case versionNotSupported(SemanticVersion)
  }

  // v9.9.0 is the release where the `/version` API first existed properly
  static let minimumSupportedServerVersion = SemanticVersion(major: 9, minor: 9, patch: 0)

  private let realmController: RealmController
  private let account: AccountController
  private let api: EmonCMSAPI
  private let realm: Realm

  private var cancellables = Set<AnyCancellable>()

  // Inputs

  // Outputs

  init(realmController: RealmController, account: AccountController, api: EmonCMSAPI) {
    self.realmController = realmController
    self.account = account
    self.api = api
    self.realm = realmController.createMainRealm()
  }

  private func updateEmoncmsServerVersion() -> AnyPublisher<String?, Never> {
    let account = self.realm.object(ofType: Account.self, forPrimaryKey: self.account.uuid)
    return self.api.version(self.account.credentials)
      .map { [weak self] version -> String in
        guard let self = self else { return version }

        guard let account = account else { return version }

        do {
          try self.realm.write {
            account.serverVersion = version
          }
        } catch {}

        return version
      }
      .replaceError(with: account?.serverVersion)
      .eraseToAnyPublisher()
  }

  func checkEmoncmsServerVersion() -> AnyPublisher<Void, AccountViewModelError> {
    return self.updateEmoncmsServerVersion()
      .map { version -> SemanticVersion? in
        if let version = version {
          return SemanticVersion(string: version)
        }
        return nil
      }
      .setFailureType(to: AccountViewModelError.self)
      .flatMap { version -> AnyPublisher<Void, AccountViewModelError> in
        if let version = version, version < AccountViewModel.minimumSupportedServerVersion {
          return Fail<Void, AccountViewModelError>(error: .versionNotSupported(version)).eraseToAnyPublisher()
        } else {
          return Empty().eraseToAnyPublisher()
        }
      }
      .eraseToAnyPublisher()
  }
}

extension AccountViewModel.AccountViewModelError: Equatable {}
