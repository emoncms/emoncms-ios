//
//  Realm+Combine.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 01/08/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import Realm
import RealmSwift

public protocol NotificationEmitter {
    associatedtype ElementType: RealmCollectionValue

    /**
     Returns a `NotificationToken`, which while retained enables change notifications for the current collection.

     - returns: `NotificationToken` - retain this value to keep notifications being emitted for the current collection.
     */
    func observe(_ block: @escaping (RealmCollectionChange<Self>) -> Void) -> NotificationToken

    func toArray() -> [ElementType]

    func toAnyCollection() -> AnyRealmCollection<ElementType>
}

extension List: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<Element>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

extension AnyRealmCollection: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

extension Results: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

extension LinkingObjects: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

public extension Publishers {

  struct RealmCollection<Element: NotificationEmitter>: Publisher {

    public typealias Output = Element
    public typealias Failure = Error

    private let collection: Element
    private let synchronousStart: Bool

    init(collection: Element, synchronousStart: Bool) {
      self.collection = collection
      self.synchronousStart = synchronousStart
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Failure == Failure, S.Input == Output {
      let subscription = RealmCollectionSubscription(subscriber: subscriber, collection: self.collection, synchronousStart: self.synchronousStart)
      subscriber.receive(subscription: subscription)
    }

  }

  private class RealmCollectionSubscription<SubscriberType: Subscriber, Element: NotificationEmitter>: Subscription
    where SubscriberType.Input == Element, SubscriberType.Failure == Error
  {
    var subscriber: SubscriberType?
    var observeToken: NotificationToken?
    let collection: Element

    init(subscriber: SubscriberType, collection: Element, synchronousStart: Bool) {
      self.subscriber = subscriber
      self.collection = collection

//      if synchronousStart {
//        _ = subscriber.receive(collection)
//      }

      self.observeToken = collection.observe { [weak self] changeset in
        guard let self = self else { return }

        let value: Element

        switch changeset {
        case let .initial(latestValue):
//          guard !synchronousStart else { return }
          value = latestValue

        case .update(let latestValue, _, _, _):
          value = latestValue

        case let .error(error):
          self.subscriber?.receive(completion: .failure(error))
          return
        }

        _ = self.subscriber?.receive(value)
      }
    }

    func request(_ demand: Subscribers.Demand) {
    }

    func cancel() {
      self.subscriber = nil
      self.observeToken = nil
    }
  }

}

public extension Publishers {

  static func collection<Element: NotificationEmitter>(from collection: Element, synchronousStart: Bool = true) -> Publishers.RealmCollection<Element> {
    return RealmCollection(collection: collection, synchronousStart: synchronousStart)
  }

  static func array<Element: NotificationEmitter>(from collection: Element, synchronousStart: Bool = true) -> AnyPublisher<[Element.ElementType], Error> {
    return RealmCollection(collection: collection, synchronousStart: synchronousStart)
      .map { $0.toArray() }
      .eraseToAnyPublisher()
  }

}
