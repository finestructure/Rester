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

        waitForExpectations(timeout: 5)
    }

}
