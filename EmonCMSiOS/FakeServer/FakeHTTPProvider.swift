//
//  FakeHTTPProvider.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift

final class FakeHTTPProvider: HTTPRequestProvider {

  enum FakeHTTPProviderError: Error {
    case unknown
    case invalidParameters
  }

  struct Config {
    struct Feed {
      let id: String
      let name: String
      let tag: String
      let interval: Int
      let kwhFeed: (id: String, name: String)?
    }

    let startTime: Date
    let feeds: [Feed]
  }

  let config: Config

  init(config: Config) {
    self.config = config
    self.createFeeds()
  }



  struct Feed {
    let id: String
    let name: String
    let tag: String
  }

  private var feeds = [String:Feed]()
  private let feedEngine = FakeEmonCMSFeedEngine()

  private func createFeeds() {
    for feedConfig in self.config.feeds {
      let feed = Feed(id: feedConfig.id, name: feedConfig.name, tag: feedConfig.tag)
      self.feeds[feedConfig.id] = feed
      self.feedEngine.create(id: feedConfig.id, interval: TimeInterval(feedConfig.interval))

      if let kwhFeedConfig = feedConfig.kwhFeed {
        let kwhFeed = Feed(id: kwhFeedConfig.id, name: kwhFeedConfig.name, tag: feedConfig.tag)
        self.feeds[kwhFeedConfig.id] = kwhFeed
        self.feedEngine.create(id: kwhFeedConfig.id, interval: TimeInterval(feedConfig.interval))
      }
    }
  }

  private func createFeedData(untilTime: Date) {
    guard untilTime > self.config.startTime else { return }

    for feedConfig in self.config.feeds {
      let id = feedConfig.id
      guard
        let meta = self.feedEngine.getMeta(id: id),
        let nPoints = self.feedEngine.nPoints(id: id)
      else { continue }

      var timeToCreateAt: TimeInterval
      if let startTime = meta.startTime {
        timeToCreateAt = startTime + (Double(nPoints + 1) * meta.interval)
      } else {
        timeToCreateAt = self.config.startTime.timeIntervalSince1970
      }

      while timeToCreateAt < untilTime.timeIntervalSince1970 {
        let value = Double.random(in: 0...3000)
        self.feedEngine.post(id: id, time: timeToCreateAt, value: value)

        if let kwhFeed = feedConfig.kwhFeed {
          let kwhValue = (value / 1000.0) * (meta.interval / 3600.0)
          let lastValue = self.feedEngine.lastValue(id: kwhFeed.id)?.value ?? 0
          self.feedEngine.post(id: kwhFeed.id, time: timeToCreateAt, value: lastValue + kwhValue)
        }

        timeToCreateAt += meta.interval
      }
    }
  }

  private func feedDataForFeed(withId id: String) -> [String:Any]? {
    guard
      let feed = self.feeds[id],
      let meta = self.feedEngine.getMeta(id: id)
      else { return nil }

    let lastValue = self.feedEngine.lastValue(id: id)
    let feedData: [String:Any] = [
      "id": id,
      "name": feed.name,
      "tag": feed.tag,
      "time": lastValue?.time ?? 0,
      "value": lastValue?.value ?? 0,
      "start_time": meta.startTime ?? 0,
      "interval": meta.interval
    ]
    return feedData
  }

  private func feedList(query: [String:String]) throws -> Any {
    var feedsData = [[String:Any]]()
    for (id, _) in self.feeds {
      guard let feedData = self.feedDataForFeed(withId: id) else { continue }
      feedsData.append(feedData)
    }
    return feedsData
  }

  private func feedAGet(query: [String:String]) throws -> Any {
    guard let id = query["id"] else {
      throw FakeHTTPProviderError.invalidParameters
    }

    guard let feedData = self.feedDataForFeed(withId: id) else { return [:] }
    return feedData
  }

  private func feedGet(query: [String:String]) throws -> Any {
    guard
      let id = query["id"],
      let field = query["field"]
    else {
      throw FakeHTTPProviderError.invalidParameters
    }

    guard let feedData = self.feedDataForFeed(withId: id) else { return "" }
    return feedData[field] ?? ""
  }

  private func feedData(query: [String:String]) throws -> Any {
    guard
      let id = query["id"],
      let startString = query["start"],
      let start = TimeInterval(startString),
      let endString = query["end"],
      let end = TimeInterval(endString)
      else {
        throw FakeHTTPProviderError.invalidParameters
    }

    if
      let intervalString = query["interval"],
      let interval = Int(intervalString)
    {
      return self.feedEngine.getData(id: id, start: start, end: end, interval: interval)
        .map { point in
          return [point.time, point.value ?? 0]
      }
    } else if
      let modeString = query["mode"],
      let mode = FakeEmonCMSFeedEngine.DMYMode(rawValue: modeString)
    {
      return self.feedEngine.getDataDMY(id: id, start: start, end: end, mode: mode)
        .map { point in
          return [point.time, point.value ?? 0]
      }
    }

    throw FakeHTTPProviderError.invalidParameters
  }

  private func feedValue(query: [String:String]) throws -> Any {
    guard let id = query["id"] else {
      throw FakeHTTPProviderError.invalidParameters
    }

    return feedEngine.lastValue(id: id)?.value ?? 0
  }

  private func feedFetch(query: [String:String]) throws -> Any {
    guard let ids = query["ids"]?.split(separator: ",") else {
      throw FakeHTTPProviderError.invalidParameters
    }

    var feedValues = [Double]()
    for id in ids {
      let value = feedEngine.lastValue(id: String(id))?.value ?? 0
      feedValues.append(value)
    }
    return feedValues
  }

  private func error(query: [String:String]) throws -> Any {
    throw FakeHTTPProviderError.unknown
  }



  func request(url: URL) -> Observable<Data> {
    guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
      else {
        return Observable.empty()
    }

    let path = urlComponents.path
    let queryItems = urlComponents.queryItems ?? []
    let queryValues = queryItems.reduce([String:String]()) { (dictionary, item) in
      var mutableDictionary = dictionary
      mutableDictionary[item.name] = item.value ?? ""
      return mutableDictionary
    }

    guard queryValues["apikey"] == "ilikecats" else {
      return Observable.error(HTTPRequestProviderError.httpError(code: 401))
    }

    self.createFeedData(untilTime: Date())

    let routeFunc: (_ query: [String:String]) throws -> Any
    switch path {
    case "/feed/list.json":
      routeFunc = feedList
    case "/feed/aget.json":
      routeFunc = feedAGet
    case "/feed/get.json":
      routeFunc = feedGet
    case "/feed/data.json":
      routeFunc = feedData
    case "/feed/value.json":
      routeFunc = feedValue
    case "/feed/fetch.json":
      routeFunc = feedFetch
    default:
      routeFunc = error
      break
    }

    if
      let responseObject = try? routeFunc(queryValues),
      let responseData = try? JSONSerialization.data(withJSONObject: responseObject, options: [])
    {
      return Observable.just(responseData)
    }

    return Observable.error(HTTPRequestProviderError.unknown)
  }

}
