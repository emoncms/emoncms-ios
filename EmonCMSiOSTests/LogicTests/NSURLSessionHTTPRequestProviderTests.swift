//
//  NSURLSessionHTTPRequestProvider.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 23/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Foundation
import Nimble
import Quick

final class MockURLSessionDataTask: URLSessionDataTask {
  override func resume() {}
  override func cancel() {}
}

final class MockURLSession: URLSession {
  var nextData: Data?
  var nextResponse: URLResponse?
  var nextError: Error?

  override func dataTask(with request: URLRequest,
                         completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
  {
    DispatchQueue.main.async {
      completionHandler(self.nextData, self.nextResponse, self.nextError)
    }
    return MockURLSessionDataTask()
  }
}

final class NSURLSessionHTTPRequestProviderTests: QuickSpec {
  override func spec() {
    var scheduler: TestScheduler!
    var session: MockURLSession!
    var provider: NSURLSessionHTTPRequestProvider!

    beforeEach {
      scheduler = TestScheduler(initialClock: 0)
      session = MockURLSession()
      provider = NSURLSessionHTTPRequestProvider(session: session)
    }

    describe("NSURLSessionHTTPRequestProvider") {
      it("should create successfully") {
        _ = NSURLSessionHTTPRequestProvider()
      }

      it("should return data") {
        let url = URL(string: "http://localhost")!
        let data = Data(base64Encoded: "ZW1vbmNtcyByb2NrcyE=")!

        session.nextData = data
        session.nextResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2.0", headerFields: nil)
        session.nextError = nil

        let sut = provider.request(url: url)

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let expected: TestSequence<Data, HTTPRequestProviderError> = [
          (200, .subscription),
          (300, .input(data)),
          (300, .completion(.finished))
        ]

        expect(results.recordedOutput).toEventually(equal(expected), timeout: .seconds(1))
      }

      it("should error when response code is an error code") {
        let url = URL(string: "http://localhost")!
        let data = Data(base64Encoded: "ZW1vbmNtcyByb2NrcyE=")!

        session.nextData = data
        session.nextResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: "2.0", headerFields: nil)
        session.nextError = nil

        let sut = provider.request(url: url)

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let expected: TestSequence<Data, HTTPRequestProviderError> = [
          (200, .subscription),
          (300, .completion(.failure(.httpError(code: 401))))
        ]

        expect(results.recordedOutput).toEventually(equal(expected), timeout: .seconds(1))
      }

      it("should error when response is non-HTTP") {
        let url = URL(string: "http://localhost")!
        let data = Data(base64Encoded: "ZW1vbmNtcyByb2NrcyE=")!

        session.nextData = data
        session
          .nextResponse = URLResponse(url: url, mimeType: nil, expectedContentLength: data.count, textEncodingName: nil)
        session.nextError = nil

        let sut = provider.request(url: url)

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let expected: TestSequence<Data, HTTPRequestProviderError> = [
          (200, .subscription),
          (300, .completion(.failure(.networkError)))
        ]

        expect(results.recordedOutput).toEventually(equal(expected), timeout: .seconds(1))
      }

      it("should error when no data or response") {
        let url = URL(string: "http://localhost")!

        session.nextData = nil
        session.nextResponse = nil
        session.nextError = nil

        let sut = provider.request(url: url)

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let expected: TestSequence<Data, HTTPRequestProviderError> = [
          (200, .subscription),
          (300, .completion(.failure(.unknown)))
        ]

        expect(results.recordedOutput).toEventually(equal(expected), timeout: .seconds(1))
      }

      it("should error when ATS failure") {
        let url = URL(string: "http://localhost")!

        session.nextData = nil
        session.nextResponse = nil
        session
          .nextError = NSError(domain: NSURLErrorDomain, code: NSURLErrorAppTransportSecurityRequiresSecureConnection,
                               userInfo: nil)

        let sut = provider.request(url: url)

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let expected: TestSequence<Data, HTTPRequestProviderError> = [
          (200, .subscription),
          (300, .completion(.failure(.atsFailed)))
        ]

        expect(results.recordedOutput).toEventually(equal(expected), timeout: .seconds(1))
      }

      it("should error when random NSError") {
        let url = URL(string: "http://localhost")!

        session.nextData = nil
        session.nextResponse = nil
        session.nextError = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)

        let sut = provider.request(url: url)

        scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        let results = scheduler.start { sut }

        let expected: TestSequence<Data, HTTPRequestProviderError> = [
          (200, .subscription),
          (300, .completion(.failure(.unknown)))
        ]

        expect(results.recordedOutput).toEventually(equal(expected), timeout: .seconds(1))
      }
    }

    it("should return data for a form request") {
      let url = URL(string: "http://localhost")!
      let data = Data(base64Encoded: "ZW1vbmNtcyByb2NrcyE=")!

      session.nextData = data
      session.nextResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2.0", headerFields: nil)
      session.nextError = nil

      let sut = provider.request(url: url, formData: ["foo": "bar"])

      scheduler.schedule(after: 300) { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
      let results = scheduler.start { sut }

      let expected: TestSequence<Data, HTTPRequestProviderError> = [
        (200, .subscription),
        (300, .input(data)),
        (300, .completion(.finished))
      ]

      expect(results.recordedOutput).toEventually(equal(expected), timeout: .seconds(1))
    }
  }
}
