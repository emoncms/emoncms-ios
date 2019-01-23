//
//  NSURLSessionHTTPRequestProvider.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Quick
import Nimble
import RxSwift
import RxTest
@testable import EmonCMSiOS

final class MockURLSessionDataTask: URLSessionDataTask {
  override func resume() { return }
  override func cancel() { return }
}

final class MockURLSession: URLSession {

  var nextData: Data?
  var nextResponse: URLResponse?
  var nextError: Error?

  override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    DispatchQueue.main.async {
      completionHandler(self.nextData, self.nextResponse, self.nextError)
    }
    return MockURLSessionDataTask()
  }

}

final class NSURLSessionHTTPRequestProviderTests: QuickSpec {

  override func spec() {

    var disposeBag: DisposeBag!
    var scheduler: TestScheduler!
    var session: MockURLSession!
    var provider: NSURLSessionHTTPRequestProvider!

    beforeEach {
      disposeBag = DisposeBag()
      scheduler = TestScheduler(initialClock: 0)
      session = MockURLSession()
      provider = NSURLSessionHTTPRequestProvider(session: session)
    }

    describe("NSURLSessionHTTPRequestProvider") {
      it("should return data") {
        let observer = scheduler.createObserver(Data.self)
        let url = URL(string: "http://localhost")!
        let data = Data(base64Encoded: "ZW1vbmNtcyByb2NrcyE=")!

        session.nextData = data
        session.nextResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2.0", headerFields: nil)
        session.nextError = nil

        scheduler.scheduleAt(10, action: {
          provider.request(url: url)
            .subscribe(observer)
            .disposed(by: disposeBag)
        })

        scheduler.start()

        let expected: [Recorded<Event<Data>>] = [
          .next(10, data),
          .completed(10)
        ]

        expect(observer.events).toEventually(equal(expected), timeout: 1)
      }

      it("should error when response code is an error code") {
        let observer = scheduler.createObserver(Data.self)
        let url = URL(string: "http://localhost")!
        let data = Data(base64Encoded: "ZW1vbmNtcyByb2NrcyE=")!

        session.nextData = data
        session.nextResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: "2.0", headerFields: nil)
        session.nextError = nil

        scheduler.scheduleAt(10, action: {
          provider.request(url: url)
            .subscribe(observer)
            .disposed(by: disposeBag)
        })

        scheduler.start()

        let expected: [Recorded<Event<Data>>] = [
          .error(10, HTTPRequestProviderError.httpError(code: 401)),
        ]

        expect(observer.events).toEventually(equal(expected), timeout: 1)
      }

      it("should error when response is non-HTTP") {
        let observer = scheduler.createObserver(Data.self)
        let url = URL(string: "http://localhost")!
        let data = Data(base64Encoded: "ZW1vbmNtcyByb2NrcyE=")!

        session.nextData = data
        session.nextResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
        session.nextError = nil

        scheduler.scheduleAt(10, action: {
          provider.request(url: url)
            .subscribe(observer)
            .disposed(by: disposeBag)
        })

        scheduler.start()

        let expected: [Recorded<Event<Data>>] = [
          .error(10, HTTPRequestProviderError.networkError),
          ]

        expect(observer.events).toEventually(equal(expected), timeout: 1)
      }

      it("should error when no data or response") {
        let observer = scheduler.createObserver(Data.self)
        let url = URL(string: "http://localhost")!

        session.nextData = nil
        session.nextResponse = nil
        session.nextError = nil

        scheduler.scheduleAt(10, action: {
          provider.request(url: url)
            .subscribe(observer)
            .disposed(by: disposeBag)
        })

        scheduler.start()

        let expected: [Recorded<Event<Data>>] = [
          .error(10, HTTPRequestProviderError.unknown),
          ]

        expect(observer.events).toEventually(equal(expected), timeout: 1)
      }

      it("should error when ATS failure") {
        let observer = scheduler.createObserver(Data.self)
        let url = URL(string: "http://localhost")!

        session.nextData = nil
        session.nextResponse = nil
        session.nextError = NSError(domain: NSURLErrorDomain, code: NSURLErrorAppTransportSecurityRequiresSecureConnection, userInfo: nil)

        scheduler.scheduleAt(10, action: {
          provider.request(url: url)
            .subscribe(observer)
            .disposed(by: disposeBag)
        })

        scheduler.start()

        let expected: [Recorded<Event<Data>>] = [
          .error(10, HTTPRequestProviderError.atsFailed),
          ]

        expect(observer.events).toEventually(equal(expected), timeout: 1)
      }

      it("should error when random NSError") {
        let observer = scheduler.createObserver(Data.self)
        let url = URL(string: "http://localhost")!

        session.nextData = nil
        session.nextResponse = nil
        session.nextError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        scheduler.scheduleAt(10, action: {
          provider.request(url: url)
            .subscribe(observer)
            .disposed(by: disposeBag)
        })

        scheduler.start()

        let expected: [Recorded<Event<Data>>] = [
          .error(10, HTTPRequestProviderError.unknown),
          ]

        expect(observer.events).toEventually(equal(expected), timeout: 1)
      }
    }

  }

}
