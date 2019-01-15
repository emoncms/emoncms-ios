//
//  EmonCMSiOSTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 15/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
@testable import EmonCMSiOS

class EmonCMSAPITests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var requestProvider: MockHTTPRequestProvider!
    var api: EmonCMSAPI!
    var accountCredentials: AccountCredentials!

    func call<T>(api: Observable<T>, observer: TestableObserver<T>, expect: @escaping () -> Void) {
      let sharedResult = api.share(replay: 1)

      sharedResult
        .subscribe(observer)
        .disposed(by: disposeBag)

      waitUntil { done in
        sharedResult
          .subscribe(
            onError: { error in
              fail(error.localizedDescription)
              done()
            },
            onCompleted: {
              expect()
              done()
          })
          .disposed(by: disposeBag)
      }
    }

    beforeEach {
      disposeBag = DisposeBag()
      scheduler = TestScheduler(initialClock: 0)
      requestProvider = MockHTTPRequestProvider()
      api = EmonCMSAPI(requestProvider: requestProvider)
      accountCredentials = AccountCredentials(url: "http://test", apiKey: "ilikecats")
    }

    describe("feedList") {
      it("should return feeds") {
        let observer = scheduler.createObserver([Feed].self)

        let result = api.feedList(accountCredentials).share(replay: 1)

        call(api: result, observer: observer) {
          expect(observer.events.count).to(equal(2))
          expect(observer.events[0].value.element).notTo(beNil())
          expect(observer.events[0].value.element!.count).to(equal(2))
        }

        scheduler.start()
      }
    }

    describe("feedFields") {
      it("should fetch all fields for a given feed") {
        let observer = scheduler.createObserver(Feed.self)

        let result = api.feedFields(accountCredentials, id: "1")

        call(api: result, observer: observer) {
          expect(observer.events.count).to(equal(2))
          expect(observer.events[0].value.element).notTo(beNil())
        }

        scheduler.start()
      }
    }

    describe("feedField") {
      it("should fetch the given field for the feed") {
        let observer = scheduler.createObserver(String.self)

        let result = api.feedField(accountCredentials, id: "1", fieldName: "name")

        call(api: result, observer: observer) {
          expect(observer.events.count).to(equal(2))
          expect(observer.events[0].value.element).notTo(beNil())
          expect(observer.events[0].value.element).to(equal("use"))
        }

        scheduler.start()
      }
    }

    describe("feedData") {
      it("should fetch the data for the feed") {
        let observer = scheduler.createObserver([DataPoint].self)

        let result = api.feedData(accountCredentials, id: "1", at: Date()-100, until: Date(), interval: 10)

        call(api: result, observer: observer) {
          expect(observer.events.count).to(equal(2))
          expect(observer.events[0].value.element).notTo(beNil())
          expect(observer.events[0].value.element!.count).to(equal(10))
        }

        scheduler.start()
      }
    }

    describe("feedDataDaily") {
      it("should fetch the data for the feed") {
        let observer = scheduler.createObserver([DataPoint].self)

        let result = api.feedDataDaily(accountCredentials, id: "1", at: Date()-100, until: Date())

        call(api: result, observer: observer) {
          expect(observer.events.count).to(equal(2))
          expect(observer.events[0].value.element).notTo(beNil())
          expect(observer.events[0].value.element!.count).to(equal(3))
        }

        scheduler.start()
      }
    }

    describe("feedValue") {
      it("should fetch the value for the feed") {
        let observer = scheduler.createObserver(Double.self)

        let result = api.feedValue(accountCredentials, id: "1")

        call(api: result, observer: observer) {
          expect(observer.events.count).to(equal(2))
          expect(observer.events[0].value.element).notTo(beNil())
          expect(observer.events[0].value.element!).to(equal(100))
        }

        scheduler.start()
      }

      it("should fetch the value for the feeds") {
        let observer = scheduler.createObserver([String:Double].self)

        let result = api.feedValue(accountCredentials, ids: ["1", "2", "3"])

        call(api: result, observer: observer) {
          expect(observer.events.count).to(equal(2))
          expect(observer.events[0].value.element).notTo(beNil())
          expect(observer.events[0].value.element!.count).to(equal(3))
          expect(observer.events[0].value.element!).to(equal(["1":100,"2":200,"3":300]))
        }

        scheduler.start()
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
