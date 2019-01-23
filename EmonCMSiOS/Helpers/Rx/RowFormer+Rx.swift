//
//  RowFormer+Rx.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Former
import RxSwift
import RxCocoa

extension RowFormer {

  public static func rx_observable<E>(_ updater: @escaping (@escaping ((E) -> Void)) -> RowFormer) -> Observable<E> {
    return Observable<E>.create { observer in
      _ = updater { value in
        observer.onNext(value)
      }
      return Disposables.create()
    }
  }

  public static func rx_observable<E, F>(_ updater: @escaping (@escaping ((E, F) -> Void)) -> RowFormer) -> Observable<(E, F)> {
    return Observable<(E, F)>.create { observer in
      _ = updater { e, f in
        observer.onNext((e, f))
      }
      return Disposables.create()
    }
  }

}
