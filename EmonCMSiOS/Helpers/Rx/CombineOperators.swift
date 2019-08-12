//
//  RxOperators.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 16/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
import XCGLogger

extension Publisher {

  public func becomeVoid() -> Publishers.Map<Self, ()> {
    return self.map { _ in () }
  }

}

// TAKEN FROM: https://twitter.com/peres/status/1159972724577583110
struct Producer<T, E: Error>: Publisher {
  typealias Output = T
  typealias Failure = E

  private let handler: (AnySubscriber<T, E>) -> Void

  init(_ handler: @escaping (AnySubscriber<T, E>) -> Void) {
    self.handler = handler
  }

  func receive<Downstream>(subscriber: Downstream)
    where
    Downstream: Subscriber,
    E == Downstream.Failure,
    T == Downstream.Input {
      let wrap = AnySubscriber(subscriber)
      handler(wrap)
  }
}
