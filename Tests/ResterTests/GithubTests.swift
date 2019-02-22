//
//  GithubTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 22/02/2019.
//

import XCTest

@testable import ResterCore


class GithubTests: XCTestCase {
    // httpbin doesn't have any endpoints returning arrays, so we're using
    // GitHub instead

    func test_response_array_validation() throws {
        let s = """
            requests:
              releases:
                url: https://api.github.com/repos/finestructure/Rester/releases
                validation:
                  status: 200
                  json:
                    0:
                      id: .regex(\\d+)
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, result: $1) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].name, "releases")
                XCTAssertEqual(results[0].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test_negative_index() throws {
        let s = """
            requests:
              releases:
                url: https://api.github.com/repos/finestructure/Rester/releases
                validation:
                  status: 200
                  json:
                    -1:
                      id: .regex(\\d+)
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, result: $1) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].name, "releases")
                XCTAssertEqual(results[0].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

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
                    -1:
                      id: .regex(\\d+)
              latest_release:
                url: ${BASE_URL}/releases/${releases.-1.id}
                validation:
                  status: 200
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
        waitForExpectations(timeout: 10)
    }

}
