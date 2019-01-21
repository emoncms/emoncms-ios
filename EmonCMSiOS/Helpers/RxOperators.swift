//
//  RxOperators.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 16/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import RxSwift

extension ObservableType {

  public func becomeVoid() -> Observable<()> {
    return map { _ in () }
  }

  public func becomeVoidAndIgnoreElements() -> Completable {
    return becomeVoid().ignoreElements()
  }

  public func log() -> Observable<Self.E> {
    return self.do(
      onNext: {
        print("\(self): onNext <\($0)>")
      },
      onError: {
        print("\(self): onError <\($0)>")
      },
      onCompleted: {
        print("\(self): onCompleted")
      },
      onSubscribe: {
        print("\(self): onSubscribe")
      },
      onSubscribed: {
        print("\(self): onSubscribed")
      },
      onDispose: {
        print("\(self): onDispose")
      })
  }

}
