//
//  ResterTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

#if !os(watchOS)

import XCTest

import Gen
import PromiseKit
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

    func test_basic() async throws {
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
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 1)
        XCTAssert(results[0].isSuccess)
    }

    func test_substitute_env() async throws {
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
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "post")
        XCTAssert(results[0].isSuccess)
    }

    func test_response_array_validation() async throws {
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
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "post-array")
        XCTAssert(results[0].isSuccess)
    }

    func test_response_variable_legacy() async throws {
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
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "post-array")
        XCTAssert(results[0].isSuccess)
        XCTAssertEqual(results[1].name, "reference")
        XCTAssert(results[1].isSuccess)
    }

    func test_response_variable() async throws {
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
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "post-array")
        XCTAssert(results[0].isSuccess)
        XCTAssertEqual(results[1].name, "reference")
        XCTAssert(results[1].isSuccess)
    }

    func test_delay_env_var_substitution() async throws {
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
        let r = try Rester(yml: s)
        let start = Date()
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 1)
        XCTAssert(results[0].isSuccess)
        XCTAssertEqual(console.verbose, ["Delaying for 2.0s"])
        let elapsed = Date().timeIntervalSince(start)
        XCTAssert(elapsed > 2, "elapsed time must be larger than delay, was \(elapsed)")
    }

    func test_timeout_error() async throws {
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
        do {
            _ = try await r.test(before: {_ in }, after: {_ in}, timeout: 0.1)
            XCTFail("expected timeout to be raised")
        } catch {
            XCTAssertEqual(error.legibleLocalizedDescription, "request timed out: \("timeout".blue)")
        }
    }

    func test_set_up() async throws {
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
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 1)
        XCTAssert(results[0].isSuccess)
    }

    func test_mode_random() async throws {
        // https://xkcd.com/221
        Current.rng = AnyRandomNumberGenerator(LCRNG(seed: 0))
        let s = """
            mode: random
            requests:
              r1:
                url: https://httpbin.org/anything
                validation:
                  status: 200
              r2:
                url: https://httpbin.org/anything
                validation:
                  status: 200
            """
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.map { $0.name }, ["r1"])
    }

    func test_request_variable_definition_pick_up() async throws {
        // Tests that a request variable defintion can be picked up in subsequent requests
        let s = """
            requests:
              r1:
                url: https://httpbin.org/anything
                validation:
                  status: 200
                variables:
                  foo: json.method
              r2:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    value: ${r1.foo}
                validation:
                  status: 200
                  json:
                    json:
                      value: GET
            """
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 2)
        XCTAssert(results[0].isSuccess)
        XCTAssert(results[1].isSuccess)
    }

    func test_request_variable_append() async throws {
        // Tests that a request variable can appended to a global
        let s = """
            variables:
              values: []
            requests:
              r1:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    value: r1
                validation:
                  status: 200
                variables:
                  # json.json - first json references json response decoding
                  #             second json references the field 'json' returned
                  #             from httpbin
                  values: .append(json.json.value)
              r2:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    value: r2
                validation:
                  status: 200
                variables:
                  values: .append(json.json.value)
            """
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 2)
        XCTAssert(results[0].isSuccess)
        XCTAssert(results[1].isSuccess)
        XCTAssertEqual(r.variables["values"], .array(["r1", "r2"]))
    }

    func test_request_variable_remove() async throws {
        // Tests that a request variable can removed from a global
        let s = """
            variables:
              values: [r0, r1, r2, r3]
            requests:
              r1:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    value: r1
                validation:
                  status: 200
                variables:
                  # json.json - first json references json response decoding
                  #             second json references the field 'json' returned
                  #             from httpbin
                  values: .remove(json.json.value)
              r2:
                url: https://httpbin.org/anything
                method: POST
                body:
                  json:
                    value: r2
                validation:
                  status: 200
                variables:
                  values: .remove(json.json.value)
            """
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results.count, 2)
        XCTAssert(results[0].isSuccess)
        XCTAssert(results[1].isSuccess)
        XCTAssertEqual(r.variables["values"], .array(["r0", "r3"]))
    }

    func test_request_when() async throws {
        let s = """
            variables:
              values: []
            requests:
              r1:
                when:
                  values: .doesNotEqual([])
                url: https://httpbin.org/anything
                validation:
                  status: 500  # deliberately invalid, as this test must not run
            """
        let r = try Rester(yml: s)
        let results = try await r.test(before: {_ in}, after: {_ in})
        XCTAssertEqual(results, [.skipped("r1")])
    }

    func test_cancel() async throws {
        let s = """
            variables:
              API_URL: https://httpbin.org
            requests:
              timeout:
                url: ${API_URL}/delay/11
                method: GET
                validation:
                  status: 200
              not reached:
                url: ${API_URL}/anything
                method: GET
                validation:
                  status: 200
            """
        let r = try Rester(yml: s)
        let task = Task {
            do {
                _ = try await r.test(before: {_ in}, after: {_ in})
                XCTFail("must not receive any results when cancelling")
            } catch is CancellationError {
                // ok
            } catch {
                XCTFail(error.legibleLocalizedDescription)
            }
        }
        print("cancelling ...")
        r.cancel()
        await task.value
    }

}

#endif  // !os(watchOS)
