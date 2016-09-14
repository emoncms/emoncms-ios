//
//  AddAccountViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import RxSwift

class AddAccountViewModel {

  var url = Variable<String>("")
  var apikey = Variable<String>("")

  func canSave() -> Observable<Bool> {
    return Observable
      .combineLatest(self.url.asObservable(), self.apikey.asObservable()) { url, apikey in
        return !url.isEmpty && !apikey.isEmpty
    }
  }
  
}
