//
//  AppData.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 28/12/2018.
//  Copyright © 2018 Matt Galloway. All rights reserved.
//

import Foundation
import Combine

import RealmSwift

enum AppCategory: String, CaseIterable {

  case myElectric
  case mySolar
  case mySolarDivert

}

final class AppData: Object {

  @objc dynamic var uuid: String = UUID().uuidString
  @objc dynamic var name: String = "App"
  @objc private dynamic var category: String = "NULL"
  @objc private dynamic var feedsJson: Data?

  var feedsChanged: AnyPublisher<Void, Never> {
    return self.publisher(for: \.feedsJson)
      .removeDuplicates()
      .becomeVoid()
      .eraseToAnyPublisher()
  }

  var appCategory: AppCategory {
    get {
      return AppCategory(rawValue: category)! // TODO: Handle this if it doesn't exist?
    }
    set {
      self.category = newValue.rawValue
    }
  }

  private var feeds: [String:String] {
    get {
      guard let dataJson = self.feedsJson else {
        return [String:String]()
      }
      do {
        if let feeds = try JSONSerialization.jsonObject(with: dataJson, options: []) as? [String:String] {
          return feeds
        }
      } catch {}
      return [String:String]()
    }

    set {
      do {
        let data = try JSONSerialization.data(withJSONObject: newValue, options: [])
        self.feedsJson = data
      } catch {
        self.feedsJson = nil
      }
    }
  }

  override class func primaryKey() -> String? {
    return "uuid"
  }

  override class func ignoredProperties() -> [String] {
    return ["appCategory", "feeds"]
  }

  func feed(forName name: String) -> String? {
    return self.feeds[name]
  }

  func setFeed(_ id: String, forName name: String) {
    var feeds = self.feeds
    feeds[name] = id
    self.feeds = feeds
  }

}
