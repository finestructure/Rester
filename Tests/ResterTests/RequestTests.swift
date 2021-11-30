//
//  RequestTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 04/02/2019.
//

#if !os(watchOS)

import XCTest

import Path
import Yams
@testable import ResterCore


class RequestTests: XCTestCase {

    func test_post_json() async throws {
        let s = """
            url: https://httpbin.org/anything
            method: POST
            body:
              json:
                foo: bar
            validation:
              status: 200
              json:
                method: POST
                json:
                  foo: bar
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

    func test_post_form() async throws {
        let s = """
            url: https://httpbin.org/anything
            method: POST
            body:
              form:
                foo: bar
            validation:
              status: 200
              json:
                method: POST
                form:
                  foo: bar
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

    func test_post_multipart() async throws {
        let testFile = path(fixture: "test.jpg")!
        let s = """
            url: https://httpbin.org/anything
            method: POST
            body:
              multipart:
                file: .file(\(testFile))
            validation:
              status: 200
              json:
                method: POST
                headers:
                  Content-Type: multipart/form-data; charset=utf-8; boundary=__X_RESTER_BOUNDARY__
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

    func test_post_text() async throws {
        let s = """
            url: https://httpbin.org/anything
            method: POST
            body:
              text: foobar
            validation:
              status: 200
              json:
                method: POST
                headers:
                  Content-Type: text/plain; charset=utf-8
                data: foobar
        """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

    func test_post_file() async throws {
        let testFile = path(fixture: "test.jpg")!
        let s = """
             url: https://httpbin.org/anything
             method: POST
             body:
               file: .file(\(testFile))
             validation:
               status: 200
               json:
                 method: POST
                 headers:
                   Content-Type: image/jpeg
                 data: dummy data
         """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

    func test_put_json() async throws {
        let s = """
            url: https://httpbin.org/anything
            method: PUT
            body:
              json:
                foo: bar
            validation:
              status: 200
              json:
                method: PUT
                json:
                  foo: bar
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

    func test_delete() async throws {
        let s = """
            url: https://httpbin.org/anything
            method: DELETE
            validation:
              status: 200
              json:
                method: DELETE
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

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

    func test_request_execute_with_headers() async throws {
        let s = """
            url: https://httpbin.org/anything
            method: GET
            headers:
              H1: header1
        """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "basic", details: d)

        let res = try await r.execute()
        XCTAssertEqual(res.response.statusCode, 200)
        // httpbin returns the request data back to us:
        // { "headers": { ... } }
        struct Result: Codable { let headers: Request.Headers }
        let result = try JSONDecoder().decode(Result.self, from: res.data)
        XCTAssertEqual(result.headers["H1"], "header1")
    }

    func test_validate_headers() async throws {
        let s = """
            url: https://httpbin.org/anything
            validation:
              status: 200
              headers:
                Content-Type: application/json
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
    }

    func test_parse_query() throws {
        let s = """
            url: https://foo.bar
            query:
              q1: value
              q2: 2
        """
        let r = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(r.query, ["q1": "value", "q2": 2])
    }

    func test_request_execute_with_query() async throws {
        let s = """
            url: https://httpbin.org/anything
            method: GET
            query:
              q: value
        """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "basic", details: d)

        let res = try await r.execute()
        XCTAssertEqual(res.response.statusCode, 200)
        // httpbin returns the request parameters back to us:
        // { "args": { ... } }
        struct Result: Codable { let args: Request.QueryParameters }
        let result = try JSONDecoder().decode(Result.self, from: res.data)
        XCTAssertEqual(result.args["q"], "value")
    }

    func test_parse_delay() throws {
        do {  // Int
            let s = """
                url: https://httpbin.org/anything
                delay: 5
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.delay, 5)
        }
        do {  // Double
            let s = """
                url: https://httpbin.org/anything
                delay: 4.2
            """
            let r = try YAMLDecoder().decode(Request.Details.self, from: s)
            XCTAssertEqual(r.delay, .double(4.2))
        }
    }

    func test_delay_substitution() throws {
        // Details decoding keeps string
        let s = """
            url: https://httpbin.org/anything
            delay: ${DELAY}
        """
        let details = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(details.delay, .string("${DELAY}"))

        // Request substitution creates valid request.delay: TimeInterval
        let req = Request(name: "req", details: details)

        do {  // Substitute int value
            let vars: [Key: Value] = ["DELAY": 2]
            let resolved = try req.substitute(variables: vars)
            XCTAssertEqual(resolved.delay, 2)
        }

        do {  // Substitute double value
            let vars: [Key: Value] = ["DELAY": .double(2.2)]
            let resolved = try req.substitute(variables: vars)
            XCTAssertEqual(resolved.delay, 2.2)
        }

        do {  // Substitute string value
            let vars: [Key: Value] = ["DELAY": "2"]
            let resolved = try req.substitute(variables: vars)
            XCTAssertEqual(resolved.delay, 2)
        }
    }

    func test_delay_execution() async throws {
        let console = TestConsole()
        Current.console = console
        let s = """
            delay: 1
            url: https://httpbin.org/anything
            validation:
              status: 200
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let start = Date()
        let res = try await r.test()
        XCTAssertEqual(res, ValidationResult.valid)
        XCTAssertEqual(console.verbose, ["Delaying for 1.0s"])
        let elapsed = Date().timeIntervalSince(start)
        XCTAssert(elapsed > 1, "elapsed time must be larger than delay, was \(elapsed)")
    }

    func test_request_execute_elapsed() async throws {
        let d = Request.Details(url: "https://httpbin.org/delay/1")
        let r = Request(name: "basic", details: d)

        let res = try await r.execute()
        XCTAssertEqual(res.response.statusCode, 200)
        XCTAssert(res.elapsed >= 1.0, "elapsed must be >= 1.0, was: \(res.elapsed)")
    }

    func test_execute_validateCertificate() async throws {
#if !os(macOS)
        throw XCTSkip("switching off certificate validation only supported on macOS")
#endif
        let d = Request.Details(url: "https://self-signed.badssl.com")
        let r = Request(name: "test", details: d)

        do {  // test that verification (default case) raises exception
            _ = try await r.execute(validateCertificate: true)
            XCTFail("bad SSL certificate must not succeed")
        } catch {
            XCTAssert(error.legibleLocalizedDescription.starts(with: "The certificate for this server is invalid"), "was instead: \(error.legibleLocalizedDescription)")
        }

        do {  // test that insecure process succeeds
            let res = try await r.execute(validateCertificate: false)
            XCTAssertEqual(res.response.statusCode, 200)
        }
    }

    func test_parse_variables() throws {
        let s = """
            url: https://httpbin.org/anything
            variables:
              foo: bar
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(d.variables, ["foo": "bar"])
    }

    func test_variable_definition() async throws {
        // tests defining a new variable within a request body
        let s = """
            url: https://httpbin.org/anything
            variables:
              foo: json.method
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.execute()
        XCTAssertEqual(res.status, 200)
        XCTAssertEqual(res.variables?["foo"], "GET")
    }

    func test_variable_definition_append() async throws {
        // tests substitution for variable with append syntax
        let s = """
            url: https://httpbin.org/anything
            variables:
              foo: .append(json.method)
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.execute()
        XCTAssertEqual(res.status, 200)
        XCTAssertEqual(res.variables?["foo"], ".append(GET)")
    }

    func test_variable_definition_remove() async throws {
        // tests substitution for variable with remove syntax
        let s = """
            url: https://httpbin.org/anything
            variables:
              foo: .remove(json.method)
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        let r = Request(name: "request", details: d)
        let res = try await r.execute()
        XCTAssertEqual(res.status, 200)
        XCTAssertEqual(res.variables?["foo"], ".remove(GET)")
    }

    func test_parse_when() throws {
        let s = """
            when:
              foo: .doesNotEqual([])
            url: https://httpbin.org/anything
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(d.when, ["foo": .doesNotEqual(.array([]))])
    }

    func test_shouldExecute() throws {
        do {
            let d = Request.Details(
                url: "http://foo",
                when: ["values": .equals(1)]
            )
            let r = Request(name: "basic", details: d)
            XCTAssert(r.shouldExecute(given: ["values": 1]))
            XCTAssert(!r.shouldExecute(given: ["values": 2]))
        }
        do {
            let d = Request.Details(
                url: "http://foo",
                when: ["values": Matcher.doesNotEqual(.array([]))]
            )
            let r = Request(name: "basic", details: d)
            XCTAssert(r.shouldExecute(given: ["values": .array([1])]))
            XCTAssert(!r.shouldExecute(given: ["values": .array([])]))
        }
    }

    func test_basic_auth_header() throws {
        let s = """
            url: https://foo.bar
            headers:
              Authorization: Basic .base64(${USER}:${PASS})
        """
        let details = try YAMLDecoder().decode(Request.Details.self, from: s)
        XCTAssertEqual(details.headers, ["Authorization": "Basic .base64(${USER}:${PASS})"])

        // Ensure substitution works as expected
        let req = Request(name: "req", details: details)
        let resolved = try req.substitute(variables: ["USER": "foo", "PASS": "bar"])
        XCTAssertEqual(resolved.headers, ["Authorization": "Basic Zm9vOmJhcg=="])
    }


}


extension Request.Details {
    init(url: String, when: [Key: Matcher]? = nil) {
        self.init(url: url, method: nil, headers: nil, query: nil, body: nil, validation: nil, delay: nil, log: nil, variables: nil, when: when)
    }
}

#endif  // !os(watchOS)
