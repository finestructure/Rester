//
//  GithubTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 22/02/2019.
//

import XCTest

@testable import ResterCore


class GithubTests: XCTestCase {

    func test_response_variable() throws {
        let console = TestConsole()
        Current.console = console
        let s = """
            variables:
              BASE_URL: https://api.github.com/repos/finestructure/Rester
            requests:
              releases:
                url: ${BASE_URL}/releases
                validation:
                  status: 200
                  json:
                    0:
                      id: .regex(\\d+)
                    -1:
                      id: 15181055
                log:
                  - json.-1.id
              latest_release:
                url: ${BASE_URL}/releases/${releases.0.id}
                validation:
                  status: 200
                log:
                  - json
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, result: $1) })
            .done { results in
                // test validation results
                XCTAssertEqual(results.count, 2)
                XCTAssertEqual(results[0].name, "releases")
                XCTAssertEqual(results[0].result, .valid)
                XCTAssertEqual(results[1].name, "latest_release")
                XCTAssertEqual(results[1].result, .valid)

                // test console logs
                XCTAssertEqual(console.labels, ["-1.id", "JSON"])
                XCTAssertEqual(console.values.first as? Value?, 15181055)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

}
