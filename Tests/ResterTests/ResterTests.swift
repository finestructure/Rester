//
//  ResterTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest

@testable import ResterCore


class ResterTests: XCTestCase {

    func test_init() throws {
        let workDir = examplesDirectory()!

        let s = """
            restfiles:
              - batch/env.yml
              - batch/basic.yml
              - batch/basic2.yml
        """

        let r = try Rester(yml: s, workDir: workDir)
        XCTAssertEqual(r.allRequests.count, 2)
        XCTAssertEqual(r.allVariables, ["API_URL": "https://httpbin.org"])
        XCTAssertEqual(r.allRequests.map { $0.name }, ["basic", "basic2"])
    }

}
