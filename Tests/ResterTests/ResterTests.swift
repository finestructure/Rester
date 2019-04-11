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

    func test_delay_env_var_substitution() throws {
        Current.environment = ["DELAY": "2"]
        let console = TestConsole()
        Current.console = console
        let s = """
            requests:
              delay:
                delay: ${DELAY}
                url: https://httpbin.org/anything
                validation:
                  status: 200
            """
        let rester = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        let start = Date()
        _ = rester.test(before: {_ in}, after: { (name: $0, response: $1, result: $2) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].result, .valid)
                XCTAssertEqual(console.verbose, ["Delaying for 2.0s"])
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssert(elapsed > 2, "elapsed time must be larger than delay, was \(elapsed)")
    }

}
