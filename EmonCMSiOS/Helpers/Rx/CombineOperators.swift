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
  public func becomeVoid() -> Publishers.Map<Self, Void> {
    return self.map { _ in () }
  }
}

// INSPIRED BY: https://twitter.com/peres/status/1159972724577583110
struct Producer<T, E: Error>: Publisher {
  typealias Output = T
  typealias Failure = E

  private let handler: (Producer.Subscriber) -> Void

  init(_ handler: @escaping (Producer.Subscriber) -> Void) {
    self.handler = handler
  }

  func receive<Downstream>(subscriber: Downstream)
    where
    Downstream: Combine.Subscriber,
    E == Downstream.Failure,
    T == Downstream.Input {
    let wrap = Producer.Subscriber(downstream: AnySubscriber(subscriber))
    let subscription = Producer.Subscription(subscriber: wrap)
    subscriber.receive(subscription: subscription)
    self.handler(wrap)
  }

  public class Subscriber {
    private var downstream: AnySubscriber<T, E>
    fileprivate var cancelled = false

    init(downstream: AnySubscriber<T, E>) {
      self.downstream = downstream
    }

    func receive(_ value: T) -> Subscribers.Demand {
      return self.downstream.receive(value)
    }

    func receive(completion: Subscribers.Completion<E>) {
      self.downstream.receive(completion: completion)
    }
  }

  private class Subscription: Combine.Subscription {
    var subscriber: Producer.Subscriber?

    init(subscriber: Producer.Subscriber) {
      self.subscriber = subscriber
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
      self.subscriber?.cancelled = true
      self.subscriber = nil
    }
  }
}
