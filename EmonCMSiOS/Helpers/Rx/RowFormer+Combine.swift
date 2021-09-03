//
//  RowFormer+Combine.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

import Former

public extension RowFormer {
  static func publisher<E>(_ updater: @escaping (@escaping ((E) -> Void)) -> RowFormer)
    -> AnyPublisher<E, Never>
  {
    return Producer<E, Never> { observer in
      _ = updater { value in
        _ = observer.receive(value)
      }
    }.eraseToAnyPublisher()
  }

  static func publisher<
    E,
    F
  >(_ updater: @escaping (@escaping ((E, F) -> Void)) -> RowFormer) -> AnyPublisher<(E, F),
    Never>
  {
    return Producer<(E, F), Never> { observer in
      _ = updater { e, f in
        _ = observer.receive((e, f))
      }
    }.eraseToAnyPublisher()
  }
}
