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

}
