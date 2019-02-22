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
                      id: '15698703'
                    -1:
                      id: '15181055'
                log:
                  - json.0.id
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
                XCTAssertEqual(results.count, 2)
                XCTAssertEqual(results[0].name, "releases")
                XCTAssertEqual(results[0].result, .valid)
                XCTAssertEqual(results[1].name, "latest_release")
                XCTAssertEqual(results[1].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

}
