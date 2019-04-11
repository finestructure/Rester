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

    func test_basic() throws {
        let s = """
            variables:
              API_URL: https://httpbin.org
            requests:
              basic:
                url: ${API_URL}/anything
                method: GET
                validation:
                  status: 200
            """
        let rester = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = rester.test(before: {_ in}, after: { (name: $0, response: $1, result: $2) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].result, .valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_substitute_env() throws {
        Current.environment = ["TEST_ID": "foo"]
        let s = """
            requests:
              post:
                url: https://httpbin.org/anything
                method: POST
                body:
                  form:
                    value1: v1 ${TEST_ID}
                    value2: v2 ${TEST_ID}
                validation:
                  status: 200
                  json:
                    method: POST
                    form:
                      value1: v1 foo
                      value2: v2 ${TEST_ID}
            """
        let rester = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = rester.test(before: {_ in}, after: { (name: $0, response: $1, result: $2) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].name, "post")
                XCTAssertEqual(results[0].result, .valid)
                expectation.fulfill()
            }
            .catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_response_array_validation() throws {
        let s = """
            requests:
              post-array:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    values:
                      - a
                      - 42
                      - c
                validation:
                  status: 200
                  json:
                    json:  # what we post is returned as {"json": {"values": ...}}
                      values:
                        0: a
                        1: 42
                        -1: c
                        -2: 42
                        1: .regex(\\d+)
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, response: $1, result: $2) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].name, "post-array")
                XCTAssertEqual(results[0].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_response_variable_legacy() throws {
        // Tests references a value from a previous request's response
        // (legacy syntax .1 to reference array element at index 1)
        let s = """
            requests:
              post-array:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    values:
                      - a
                      - 42
                      - c
              reference:
                url: https://httpbin.org/anything/${post-array.json.values.1}  # sending 42
                validation:
                  status: 200
                  json:  # url is mirrored back in json response
                    url: https://httpbin.org/anything/42
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, response: $1, result: $2) })
            .done { results in
                XCTAssertEqual(results.count, 2)
                XCTAssertEqual(results[0].name, "post-array")
                XCTAssertEqual(results[0].result, .valid)
                XCTAssertEqual(results[1].name, "reference")
                XCTAssertEqual(results[1].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_response_variable() throws {
        // Tests references a value from a previous request's response
        // (using syntax [1] to reference array element at index 1)
        let s = """
            requests:
              post-array:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    values:
                      - a
                      - 42
                      - c
              reference:
                url: https://httpbin.org/anything/${post-array.json.values[1]}  # sending 42
                validation:
                  status: 200
                  json:  # url is mirrored back in json response
                    url: https://httpbin.org/anything/42
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, response: $1, result: $2) })
            .done { results in
                XCTAssertEqual(results.count, 2)
                XCTAssertEqual(results[0].name, "post-array")
                XCTAssertEqual(results[0].result, .valid)
                XCTAssertEqual(results[1].name, "reference")
                XCTAssertEqual(results[1].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
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

    func test_timeout_error() throws {
        let console = TestConsole()
        Current.console = console
        let s = """
            requests:
              # will time out with message: ❌  Error: request timed out: timeout
              timeout:
                url: https://httpbin.org/delay/10
                method: GET
                validation:
                  status: 200
              passes_1:
                url: https://httpbin.org/anything
                method: GET
                validation:
                  status: 200
              passes_2:
                url: https://httpbin.org/anything
                method: GET
                validation:
                  status: 200
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, response: $1, result: $2) }, timeout: 0.1)
            .done { _ in
                XCTFail("expected timeout to be raised")
                expectation.fulfill()
            }.catch {
                XCTAssertEqual($0.legibleLocalizedDescription, "request timed out: \("timeout".blue)")
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

}
