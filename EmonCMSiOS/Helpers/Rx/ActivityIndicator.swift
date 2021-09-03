//
//  ActivityIndicator.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/08/19.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
import Foundation

public final class ActivityIndicatorCombine {
  private let lock = NSRecursiveLock()
  private var count = 0
  private let subject = PassthroughSubject<Bool, Never>()

  var loading: Bool {
    self.lock.lock()
    let loading = self.count > 0
    self.lock.unlock()
    return loading
  }

  func asPublisher() -> AnyPublisher<Bool, Never> {
    self.subject.removeDuplicates().eraseToAnyPublisher()
  }

  fileprivate func increment() {
    self.lock.lock()
    self.count += 1
    self.subject.send(self.count > 0)
    self.lock.unlock()
  }

  fileprivate func decrement() {
    self.lock.lock()
    self.count -= 1
    self.subject.send(self.count > 0)
    self.lock.unlock()
  }
}

extension Publishers {
  public struct TrackActivity<Upstream: Publisher>: Publisher {
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    private let upstream: Upstream
    private let indicator: ActivityIndicatorCombine

    init(upstream: Upstream, indicator: ActivityIndicatorCombine) {
      self.upstream = upstream
      self.indicator = indicator
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
      let subscription = TrackActivitySubscription(
        upstream: self.upstream,
        downstream: subscriber,
        indicator: self.indicator)
      subscriber.receive(subscription: subscription)
    }
  }

  private class TrackActivitySubscription<Upstream: Publisher, Downstream: Subscriber>: Subscription, Subscriber
    where Upstream.Output == Downstream.Input, Upstream.Failure == Downstream.Failure
  {
    typealias Input = Upstream.Output
    typealias Failure = Upstream.Failure

    var upstreamSubscription: Subscription?
    let upstream: Upstream
    let downstream: Downstream
    let indicator: ActivityIndicatorCombine

    init(upstream: Upstream, downstream: Downstream, indicator: ActivityIndicatorCombine) {
      self.upstream = upstream
      self.downstream = downstream
      self.indicator = indicator
      upstream.subscribe(self)
    }

    func request(_ demand: Subscribers.Demand) {
      self.upstreamSubscription?.request(demand)
    }

    func cancel() {
      self.cancelUpstreamSubscription()
    }

    func receive(subscription: Subscription) {
      self.upstreamSubscription = subscription
      self.indicator.increment()
    }

    func receive(_ input: Input) -> Subscribers.Demand {
      return self.downstream.receive(input)
    }

    func receive(completion: Subscribers.Completion<Upstream.Failure>) {
      self.downstream.receive(completion: completion)
      self.cancelUpstreamSubscription()
    }

    private func cancelUpstreamSubscription() {
      self.indicator.decrement()
      self.upstreamSubscription?.cancel()
      self.upstreamSubscription = nil
    }
  }
}

public extension Publisher {
  func trackActivity(_ indicator: ActivityIndicatorCombine) -> Publishers.TrackActivity<Self> {
    Publishers.TrackActivity(upstream: self, indicator: indicator)
  }
}
