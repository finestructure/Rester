//
//  RequestLoggingTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 11/04/2019.
//

#if !os(watchOS)

import LegibleError
import Path
@testable import ResterCore
import XCTest
import Yams


class RequestLoggingTests: XCTestCase {

    func test_parse_log() throws {
        do {  // true
            let s = """
                url: https://httpbin.org/anything
                log: true
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.log, .bool(true))
        }
        do {  // array
            let s = """
                url: https://httpbin.org/anything
                log:
                  - status
                  - headers
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.log, .array(["status", "headers"]))
        }
        do {  // dict
            let s = """
                url: https://httpbin.org/anything
                log: json
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.log, "json")
        }
        do {  // file
            let s = """
                url: https://httpbin.org/anything
                log: .file(response.out)
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.log, ".file(response.out)")
            XCTAssertEqual(try r.log?.path(), Current.workDir/"response.out")
        }
    }

    func test_parse_log_keypath() throws {
        let s = """
            url: https://httpbin.org/anything
            log:
              - json.data.property
        """
        let r = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(r.log, .array(["json.data.property"]))
    }

    func test_log_request() throws {
        let console = TestConsole()
        Current.console = console
        let s = """
            url: https://httpbin.org/anything
            log: true
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let expectation = self.expectation(description: #function)
        _ = try r.test().map {
            XCTAssertEqual($0, ValidationResult.valid)
            // confirm the console receives output
            XCTAssertEqual(console.keys, ["Status", "Headers", "JSON"])
            XCTAssertEqual(console.values[0] as? Int, 200)
            XCTAssert("\(console.values[1])".contains("\"Content-Type\": \"application/json\""))
            XCTAssert("\(console.values[2])".contains("\"method\": \"GET\""))
            expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_log_request_json_keypath() throws {
        let console = TestConsole()
        Current.console = console
        let s = """
            url: https://httpbin.org/anything
            log:
              - json.headers.Host
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let expectation = self.expectation(description: #function)
        _ = try r.test().map {
            XCTAssertEqual($0, ValidationResult.valid)
            // confirm the console receives output
            // we're expecting the value pulled from the key path `headers.Host` in the json response
            XCTAssertEqual(console.keys, ["headers.Host"])
            XCTAssertEqual(console.values.first as? Value?, "httpbin.org")
            expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_log_request_file() throws {
        Current.workDir = testDataDirectory()!
        let fname = "log.txt"
        let logfile = Current.workDir/fname
        try logfile.delete()
        XCTAssert(!logfile.exists, "log file must not exist prior to test")

        let s = """
            url: https://httpbin.org/anything
            log: .file(\(fname))
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let expectation = self.expectation(description: #function)
        _ = try r.test().map {
            XCTAssertEqual($0, ValidationResult.valid)
            XCTAssert(logfile.exists, "log file must exist after test")
            let log = try String(contentsOf: logfile)
            XCTAssert(log.contains("\"url\": \"https://httpbin.org/anything\""), "logfile was: \(log)")
            expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

}

#endif  // !os(watchOS)
