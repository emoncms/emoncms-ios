//
//  MyElectricAppViewModel.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

class MyElectricAppViewModel: AppViewModel {

  private let api: EmonCMSAPI

  init(api: EmonCMSAPI) {
    self.api = api
  }

}
