//
//  EmonCMSAPITests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 02/12/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Foundation
import Nimble
import Quick

class EmonCMSAPIFailureTests: EmonCMSTestCase {
  override func spec() {
    var scheduler: TestScheduler!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var accountCredentials: AccountCredentials!

    func call<T>(
      api: AnyPublisher<T, EmonCMSAPI.APIError>,
      subscriber: TestableSubscriber<T, EmonCMSAPI.APIError>,
      expect: @escaping () -> Void)
    {
      let sharedResult = api.share(replay: 1)

      sharedResult
        .subscribe(subscriber)

      waitUntil { done in
        _ = sharedResult
          .sink(
            receiveCompletion: { _ in
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

    describe("apiRequest") {
      it("should fail when url is invalid 1") {
        let subscriber = scheduler.createTestableSubscriber(Data.self, EmonCMSAPI.APIError.self)

        let result = api.request(" --- NOT A VALID URL --- ", path: "", username: "", password: "")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when url is invalid 2") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber(Data.self, EmonCMSAPI.APIError.self)

        let result = api.request(accountCredentials, path: " --- NOT A VALID PATH --- ", queryItems: [:])

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.failedToCreateURL))
        }

        scheduler.resume()
      }

      it("should fail when request fails with atsFailed") {
        requestProvider.nextError = .atsFailed

        let subscriber = scheduler.createTestableSubscriber(Data.self, EmonCMSAPI.APIError.self)

        let result = api.request("test", path: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.atsFailed))
        }

        scheduler.resume()
      }

      it("should fail when request fails with invalidCredentials") {
        requestProvider.nextError = .httpError(code: 401)

        let subscriber = scheduler.createTestableSubscriber(Data.self, EmonCMSAPI.APIError.self)

        let result = api.request("test", path: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidCredentials))
        }

        scheduler.resume()
      }

      it("should fail when request fails with requestFailed from HTTP error") {
        requestProvider.nextError = .httpError(code: 400)

        let subscriber = scheduler.createTestableSubscriber(Data.self, EmonCMSAPI.APIError.self)

        let result = api.request("test", path: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when request fails with requestFailed from network error") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber(Data.self, EmonCMSAPI.APIError.self)

        let result = api.request("test", path: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }
    }

    describe("dashboards") {
      it("should fail when fetching dashboardList when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber([Dashboard].self, EmonCMSAPI.APIError.self)

        let result = api.dashboardList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching dashboardList when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber([Dashboard].self, EmonCMSAPI.APIError.self)

        let result = api.dashboardList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }
    }

    describe("feeds") {
      it("should fail when fetching feedList when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber([Feed].self, EmonCMSAPI.APIError.self)

        let result = api.feedList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedList when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber([Feed].self, EmonCMSAPI.APIError.self)

        let result = api.feedList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedFields when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber(Feed.self, EmonCMSAPI.APIError.self)

        let result = api.feedFields(accountCredentials, id: "1")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedFields when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber(Feed.self, EmonCMSAPI.APIError.self)

        let result = api.feedFields(accountCredentials, id: "1")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedField when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber(String.self, EmonCMSAPI.APIError.self)

        let result = api.feedField(accountCredentials, id: "1", fieldName: "a")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedField when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber(String.self, EmonCMSAPI.APIError.self)

        let result = api.feedField(accountCredentials, id: "1", fieldName: "a")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedData when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, EmonCMSAPI.APIError.self)

        let result = api.feedData(accountCredentials, id: "1", at: Date(), until: Date(), interval: 1)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedData when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, EmonCMSAPI.APIError.self)

        let result = api.feedData(accountCredentials, id: "1", at: Date(), until: Date(), interval: 1)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedDataDaily when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, EmonCMSAPI.APIError.self)

        let result = api.feedDataDaily(accountCredentials, id: "1", at: Date(), until: Date())

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedDataDaily when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber([DataPoint<Double>].self, EmonCMSAPI.APIError.self)

        let result = api.feedDataDaily(accountCredentials, id: "1", at: Date(), until: Date())

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedValue single when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber(Double.self, EmonCMSAPI.APIError.self)

        let result = api.feedValue(accountCredentials, id: "1")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedValue single when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber(Double.self, EmonCMSAPI.APIError.self)

        let result = api.feedValue(accountCredentials, id: "1")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedValue multiple when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber([String: Double].self, EmonCMSAPI.APIError.self)

        let result = api.feedValue(accountCredentials, ids: ["1", "2"])

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching feedValue multiple when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber([String: Double].self, EmonCMSAPI.APIError.self)

        let result = api.feedValue(accountCredentials, ids: ["1", "2"])

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }
    }

    describe("inputs") {
      it("should fail when fetching inputList when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber([Input].self, EmonCMSAPI.APIError.self)

        let result = api.inputList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching dashboardList when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber([Input].self, EmonCMSAPI.APIError.self)

        let result = api.inputList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }
    }

    describe("user") {
      it("should fail when fetching userAuth when JSON is invalid") {
        requestProvider.nextResponseOverride = "{BAD: JSON{"

        let subscriber = scheduler.createTestableSubscriber([Dashboard].self, EmonCMSAPI.APIError.self)

        let result = api.dashboardList(accountCredentials)

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidResponse))
        }

        scheduler.resume()
      }

      it("should fail when fetching userAuth when response has no success") {
        requestProvider.nextResponseOverride = "{\"apikey_read\":\"pass\"}"

        let subscriber = scheduler.createTestableSubscriber(String.self, EmonCMSAPI.APIError.self)

        let result = api.userAuth(url: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidCredentials))
        }

        scheduler.resume()
      }

      it("should fail when fetching userAuth when response has no apikey_read") {
        requestProvider.nextResponseOverride = "{\"success\":true}"

        let subscriber = scheduler.createTestableSubscriber(String.self, EmonCMSAPI.APIError.self)

        let result = api.userAuth(url: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidCredentials))
        }

        scheduler.resume()
      }

      it("should fail when fetching userAuth when response has false for success") {
        requestProvider.nextResponseOverride = "{\"success\":false,\"apikey_read\":\"pass\"}"

        let subscriber = scheduler.createTestableSubscriber(String.self, EmonCMSAPI.APIError.self)

        let result = api.userAuth(url: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.invalidCredentials))
        }

        scheduler.resume()
      }

      it("should fail when fetching userAuth when request fails") {
        requestProvider.nextError = .networkError

        let subscriber = scheduler.createTestableSubscriber(String.self, EmonCMSAPI.APIError.self)

        let result = api.userAuth(url: "test", username: "test", password: "test")

        call(api: result, subscriber: subscriber) {
          let results = subscriber.recordedOutput
          expect(results.count).to(equal(2))
          expect(results[1].1.completionError).toNot(beNil())
          expect(results[1].1.completionError!).to(equal(.requestFailed))
        }

        scheduler.resume()
      }
    }
  }
}
