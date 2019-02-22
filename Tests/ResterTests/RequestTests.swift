//
//  RequestTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 04/02/2019.
//

import XCTest

import Yams
@testable import ResterCore


class RequestTests: XCTestCase {

    func test_parse_headers() throws {
        let s = """
            url: https://foo.bar
            headers:
              H1: header1
              H2: header2
        """
        let r = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(r.headers, ["H1": "header1", "H2": "header2"])
    }

    func test_request_execute_with_headers() throws {
        let s = """
            url: https://httpbin.org/anything
            method: GET
            headers:
              H1: header1
        """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "basic", details: d)

        let expectation = self.expectation(description: #function)

        _ = try r.execute()
            .map {
                XCTAssertEqual($0.response.statusCode, 200)
                // httpbin returns the request data back to us:
                // { "headers": { ... } }
                struct Result: Codable { let headers: Request.Headers }
                let res = try JSONDecoder().decode(Result.self, from: $0.data)
                XCTAssertEqual(res.headers["H1"], "header1")
                expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_parse_query() throws {
        let s = """
            url: https://foo.bar
            query:
              q1: value
              q2: 2
        """
        let r = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(r.query, ["q1": "value", "q2": 2])
    }

    func test_request_execute_with_query() throws {
        let s = """
            url: https://httpbin.org/anything
            method: GET
            query:
              q: value
        """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "basic", details: d)

        let expectation = self.expectation(description: #function)

        _ = try r.execute()
            .map {
                XCTAssertEqual($0.response.statusCode, 200)
                // httpbin returns the request parameters back to us:
                // { "args": { ... } }
                struct Result: Codable { let args: Request.QueryParameters }
                let res = try JSONDecoder().decode(Result.self, from: $0.data)
                XCTAssertEqual(res.args["q"], "value")
                expectation.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test_parse_delay() throws {
        do {  // Int
            let s = """
                url: https://httpbin.org/anything
                delay: 5
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.delay, 5)
        }
        do {  // Double
            let s = """
                url: https://httpbin.org/anything
                delay: 4.2
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.delay, .double(4.2))
        }
    }

    func test_delay_substitution() throws {
        // Details decoding keeps string
        let s = """
            url: https://httpbin.org/anything
            delay: ${DELAY}
        """
        let details = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(details.delay, .string("${DELAY}"))

        // Request substitution creates valid request.delay: TimeInterval
        let req = Request(name: "req", details: details)

        do {  // Substitute int value
            let vars: [Key: Value] = ["DELAY": 2]
            let resolved = try req.substitute(variables: vars)
            XCTAssertEqual(resolved.delay, 2)
        }

        do {  // Substitute double value
            let vars: [Key: Value] = ["DELAY": .double(2.2)]
            let resolved = try req.substitute(variables: vars)
            XCTAssertEqual(resolved.delay, 2.2)
        }

        do {  // Substitute string value
            let vars: [Key: Value] = ["DELAY": "2"]
            let resolved = try req.substitute(variables: vars)
            XCTAssertEqual(resolved.delay, 2)
        }
    }

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

}
