//
//  Apps.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 31/12/2018.
//  Copyright © 2018 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift

protocol AppViewModel: AnyObject {

  init(account: Account, api: EmonCMSAPI, appDataId: String)

}

protocol AppConfigViewModel: AnyObject {

  init(account: Account, api: EmonCMSAPI, appDataId: String?)

  var feedListHelper: FeedListHelper { get }
  func configFields() -> [AppConfigField]
  func configData() -> [String:Any]
  func updateWithConfigData(_ data: [String:Any]) -> Observable<AppUUIDAndCategory>

}

typealias AppUUIDAndCategory = (uuid: String, category: AppCategory)

enum AppCategory: String, CaseIterable {

  case myElectric
  case mySolar

  struct Info {
    let displayName: String
    let storyboardId: String
  }

  var info: Info {
    switch self {
    case .myElectric:
      return Info(
        displayName: "MyElectric",
        storyboardId: "myElectric"
      )
    case .mySolar:
      return Info(
        displayName: "MySolar",
        storyboardId: "mySolar"
      )
    }
  }

}
