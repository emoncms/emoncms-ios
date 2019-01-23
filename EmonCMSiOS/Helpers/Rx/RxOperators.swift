//
//  RxOperators.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 16/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import RxSwift
import XCGLogger

extension ObservableType {

  public typealias LoggerFunc = (_ string: String) -> Void

  public func becomeVoid() -> Observable<()> {
    return map { _ in () }
  }

  public func log() -> Observable<Self.E> {
    return self.log({ print($0) })
  }

  public func log(_ logger: XCGLogger, level: XCGLogger.Level = .debug) -> Observable<Self.E> {
    return self.log({ logger.logln($0, level: level) })
  }

  public func log(_ logger: @escaping LoggerFunc) -> Observable<Self.E> {
    return self.do(
      onNext: {
        logger("\(self): onNext <\($0)>")
      },
      onError: {
        logger("\(self): onError <\($0)>")
      },
      onCompleted: {
        logger("\(self): onCompleted")
      },
      onSubscribe: {
        logger("\(self): onSubscribe")
      },
      onSubscribed: {
        logger("\(self): onSubscribed")
      },
      onDispose: {
        logger("\(self): onDispose")
      })
  }

}
