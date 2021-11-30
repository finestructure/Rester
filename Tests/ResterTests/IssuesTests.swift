//
//  IssuesTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 01/04/2019.
//

#if !os(watchOS)

import XCTest

import Yams
@testable import ResterCore

class IssuesTests: XCTestCase {

    func test_issue_39_referencing_into_empty_array() async throws {
        // https://github.com/finestructure/Rester/issues/39
        // terminated by signal SIGILL (Illegal instruction)
        // when referencing into empty array
        let s = """
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    values: []
                validation:
                  status: 200
                  json:
                    json:
                      values:
                        0: a
             """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "post-array", details: d)

        let result = try await r.test()
        XCTAssertEqual(result, .invalid("json invalid: key 'json' validation error: key 'values' validation error: index 0 out of bounds"))
    }

}

#endif  // !os(watchOS)
