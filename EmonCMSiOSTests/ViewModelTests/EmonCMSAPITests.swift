//
//  EmonCMSiOSTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Foundation
import Nimble
import Quick

class EmonCMSAPITests: EmonCMSTestCase {
  override func spec() {
    var scheduler: TestScheduler!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var accountCredentials: AccountCredentials!

    func call<T>(
      api: AnyPublisher<T, EmonCMSAPI.APIError>,
      subscriber: TestableSubscriber<T, EmonCMSAPI.APIError>,
      expect: @escaping () -> Void) {
      let sharedResult = api.share(replay: 1)

      sharedResult
        .subscribe(subscriber)

      waitUntil { done in
        _ = sharedResult
          .sink(
            receiveCompletion: { completion in
              switch completion {
              case .finished:
                break
              case .failure(let error):
                fail(error.localizedDescription)
              }
              expect()
              done()
            },
            receiveValue: { _ in })
      }
    }

    beforeEach {
      scheduler = TestScheduler(initialClock: 0)
      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      accountCredentials = AccountCredentials(url: "http://test", apiKey: "ilikecats")
    }

    describe("feedList") {
      it("should return feeds") {
        let subscriber = scheduler.createTestableSubscriber([Feed].self, EmonCMSAPI.APIError.self)

        let result = api.feedList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(3))
          expect(results[1].1.value).notTo(beNil())
          expect(results[1].1.value!.count).to(equal(2))
        }

        scheduler.resume()
      }
    }

    describe("feedFields") {
      it("should fetch all fields for a given feed") {
        let subscriber = scheduler.createTestableSubscriber(Feed.self, EmonCMSAPI.APIError.self)

        let result = api.feedFields(accountCredentials, id: "1")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(3))
          expect(results[1].1.value).notTo(beNil())
        }

        scheduler.resume()
      }
    }

    describe("feedField") {
      it("should fetch the given field for the feed") {
        let subscriber = scheduler.createTestableSubscriber(String.self, EmonCMSAPI.APIError.self)

        let result = api.feedField(accountCredentials, id: "1", fieldName: "name")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(3))
          expect(results[1].1.value).notTo(beNil())
          expect(results[1].1.value!).to(equal("use"))
        }

        scheduler.resume()
      }
    }

    describe("feedData") {
      it("should fetch the data for the feed") {
        let subscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, EmonCMSAPI.APIError.self)

        let result = api.feedData(accountCredentials, id: "1", at: Date() - 100, until: Date(), interval: 10)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(3))
          expect(results[1].1.value).notTo(beNil())
          expect(results[1].1.value!.count).to(equal(10))
        }

        scheduler.resume()
      }
    }

    describe("feedDataDaily") {
      it("should fetch the data for the feed") {
        let subscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, EmonCMSAPI.APIError.self)

        let result = api.feedDataDaily(accountCredentials, id: "1", at: Date() - 100, until: Date())

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(3))
          expect(results[1].1.value).notTo(beNil())
          expect(results[1].1.value!.count).to(equal(3))
        }

        scheduler.resume()
      }
    }

    describe("feedValue") {
      it("should fetch the value for the feed") {
        let subscriber = scheduler.createTestableSubscriber(Double.self, EmonCMSAPI.APIError.self)

        let result = api.feedValue(accountCredentials, id: "1")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(3))
          expect(results[1].1.value).notTo(beNil())
          expect(results[1].1.value!).to(equal(100))
        }

        scheduler.resume()
      }

      it("should fetch the value for the feeds") {
        let subscriber = scheduler.createTestableSubscriber([String: Double].self, EmonCMSAPI.APIError.self)

        let result = api.feedValue(accountCredentials, ids: ["1", "2", "3"])

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(3))
          expect(results[1].1.value).notTo(beNil())
          expect(results[1].1.value!.count).to(equal(3))
          expect(results[1].1.value!).to(equal(["1": 100, "2": 200, "3": 300]))
        }

        scheduler.resume()
      }
    }

    describe("extractAPIDetailsFromURLString") {
      it("should work for a correct url") {
        let url = "https://emoncms.org/app?readkey=1a101b101c101d101e101f101a101b10#myelectric"
        let result = EmonCMSAPI.extractAPIDetailsFromURLString(url)
        expect(result).notTo(beNil())
        expect(result!.url).to(equal("https://emoncms.org"))
        expect(result!.apiKey).to(equal("1a101b101c101d101e101f101a101b10"))
      }

      it("should work for a correct url where emoncms is not at the root") {
        let url = "https://emoncms.org/notatroot/app?readkey=1a101b101c101d101e101f101a101b10#myelectric"
        let result = EmonCMSAPI.extractAPIDetailsFromURLString(url)
        expect(result).notTo(beNil())
        expect(result!.url).to(equal("https://emoncms.org/notatroot"))
        expect(result!.apiKey).to(equal("1a101b101c101d101e101f101a101b10"))
      }

      it("should work for a correct url where /app is in the path") {
        let url = "https://emoncms.org/something/app/app?readkey=1a101b101c101d101e101f101a101b10#myelectric"
        let result = EmonCMSAPI.extractAPIDetailsFromURLString(url)
        expect(result).notTo(beNil())
        expect(result!.url).to(equal("https://emoncms.org/something/app"))
        expect(result!.apiKey).to(equal("1a101b101c101d101e101f101a101b10"))
      }

      it("should fail when the url is malformed") {
        let url = "https://www.google.com"
        let result = EmonCMSAPI.extractAPIDetailsFromURLString(url)
        expect(result).to(beNil())
      }
    }
  }
}
