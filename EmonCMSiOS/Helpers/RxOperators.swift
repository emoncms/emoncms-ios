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

  public func becomeVoidAndIgnoreElements() -> Observable<()> {
    return becomeVoid().ignoreElements()
  }

}
