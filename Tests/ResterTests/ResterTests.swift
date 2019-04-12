//
//  ResterTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest

@testable import ResterCore


class ResterTests: XCTestCase {

    func test_aggregate_variables() throws {
        // set up
        let v0: [Key: Value] = ["k0": "v0"]
        let v1: [Key: Value] = ["k1": "v1"]
        let v2: [Key: Value] = ["k2": "v2"]
        let v2a: [Key: Value] = ["k2": "v2a"]
        let rf1 = Restfile(variables: v1, requests: [], restfiles: [], setupRequests: [], mode: .sequential)
        let rf2 = Restfile(variables: v2, requests: [], restfiles: [], setupRequests: [], mode: .sequential)
        let rf2a = Restfile(variables: v2a, requests: [], restfiles: [], setupRequests: [], mode: .sequential)
        // MUT
        let res = aggregate(variables: v0, from: [rf1, rf2, rf2a])
        // assert
        XCTAssertEqual(res, ["k0": "v0", "k1": "v1", "k2": "v2a"])
    }

    func test_aggregate_requests() throws {
        // set up
        let r1 = Request(name: "r1", details: .init(url: "url"))
        let r2 = Request(name: "r2", details: .init(url: "url"))
        let rf1 = Restfile(variables: [:], requests: [r1, r2], restfiles: [], setupRequests: [], mode: .sequential)
        let r3 = Request(name: "r3", details: .init(url: "url"))
        let r4 = Request(name: "r4", details: .init(url: "url"))
        let rf2 = Restfile(variables: [:], requests: [r3, r4], restfiles: [], setupRequests: [], mode: .sequential)
        // MUT
        let res = aggregate(keyPath: \.requests, from: [rf1, rf2])
        // assert
        let names = res.map { $0.name }
        XCTAssertEqual(names, ["r1", "r2", "r3", "r4"])
    }

    func test_init() throws {
        let workDir = examplesDirectory()!

        let s = """
            restfiles:
              - batch/env.yml
              - batch/basic.yml
              - batch/basic2.yml
        """

        let r = try Rester(yml: s, workDir: workDir)
        XCTAssertEqual(r.requests.count, 2)
        XCTAssertEqual(r.variables, ["API_URL": "https://httpbin.org"])
        XCTAssertEqual(r.requests.map { $0.name }, ["basic", "basic2"])
        XCTAssertEqual(r.setupRequests.count, 0)
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

    func test_set_up() throws {
        let s = """
            variables:
              API_URL: https://httpbin.org
            set_up:
              s1:
                url: ${API_URL}/anything
                method: POST
                body:
                  json:
                    values:
                      - foo
                validation:
                  status: 200
            requests:
              r1:
                url: ${API_URL}/anything/${s1.json.values[0]}
                validation:
                  status: 200
                  json:  # url is mirrored back in json response
                    url: https://httpbin.org/anything/foo
            """
        let rester = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = rester.test(before: {_ in}, after: { (name: $0, response: $1, result: $2) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 500)
    }

}
