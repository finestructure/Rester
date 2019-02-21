import XCTest

import AnyCodable
import LegibleError
import PromiseKit
import Yams
@testable import ResterCore


extension String {
    func ends(with string: String) -> Bool {
        return reversed().starts(with: string.reversed())
    }
}


extension Restfile {
    public mutating func expandedRequest(_ requestName: String) throws -> Request {
        guard let req = requests[requestName]
            else { throw ResterError.noSuchRequest(requestName) }
        let aggregatedVariables = aggregate(variables: variables, from: restfiles)
        return try req.substitute(variables: aggregatedVariables)
    }
}


final class RequestExecutionTests: XCTestCase {

    func test_request_execute() throws {
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
        var r = try YAMLDecoder().decode(Restfile.self, from: s)

        let expectation = self.expectation(description: #function)

        _ = try r.expandedRequest("basic").execute()
            .map {
                XCTAssertEqual($0.response.statusCode, 200)
                // httpbin returns the request data back to us:
                // { "method": "GET", ... }
                struct Result: Codable { let method: String }
                let res = try JSONDecoder().decode(Result.self, from: $0.data)
                XCTAssertEqual(res.method, "GET")
                expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_validate_status() throws {
        let s = try readFixture("httpbin.yml")!
        var r = try YAMLDecoder().decode(Restfile.self, from: s)

        do {
            let expectation = self.expectation(description: #function)
            _ = try r.expandedRequest("status-success").test()
                .map { result in
                    XCTAssertEqual(result, ValidationResult.valid)
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try r.expandedRequest("status-failure").test()
                .map { result in
                    XCTAssertEqual(result, .init(invalid: "status invalid: (200) is not equal to (500)"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func test_validate_json() throws {
        let s = try readFixture("httpbin.yml")!
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-success").test()
                .map {
                    XCTAssertEqual($0, ValidationResult.valid)
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-failure").test()
                .map {
                    XCTAssertEqual($0, .init(invalid: "json invalid: key \'method\' validation error: (\"GET\") is not equal to (\"nope\")"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-failure-type").test()
                .map {
                    XCTAssertEqual($0, .init(invalid: "json invalid: key \'method\' validation error: (\"GET\") is not equal to (42)"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func test_validate_json_regex() throws {
        let s = try readFixture("httpbin.yml")!
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-regex").test()
                .map {
                    XCTAssertEqual($0, ValidationResult.valid)
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-regex-failure").test()
                .map {
                    switch $0 {
                    case .valid:
                        XCTFail("expected failure but received success")
                    case let .invalid(message, value: _):
                        XCTAssert(message.starts(with: "json invalid: key 'uuid' validation error"), "message was: \(message)")
                        XCTAssert(message.ends(with: "does not match (^\\w{8}$)"), "message was: \(message)")
                    }
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func test_request_order() throws {
        let s = """
            requests:
              first:
                url: http://foo.com
              second:
                url: http://foo.com
              3rd:
                url: http://foo.com
            """
        let rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let names = rester.requests.map { $0.name }
        XCTAssertEqual(names, ["first", "second", "3rd"])
    }

    func test_post_request_json() throws {
        let s = """
            requests:
              post:
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
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("post").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_post_request_form() throws {
        let s = """
            requests:
              post:
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
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("post").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
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
        _ = rester.test(before: {_ in}, after: { (name: $0, result: $1) })
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

    func test_put_request_json() throws {
        let s = """
            requests:
              put:
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
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("put").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_validate_headers() throws {
        let s = """
            requests:
              header-request:
                url: https://httpbin.org/anything
                validation:
                  status: 200
                  headers:
                    Content-Type: application/json
            """
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("header-request").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_delete_request() throws {
        let s = """
            requests:
              delete:
                url: https://httpbin.org/anything
                method: DELETE
                validation:
                  status: 200
                  json:
                    method: DELETE
            """
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("delete").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_delay_request() throws {
        let s = """
            requests:
              delay:
                delay: 2
                url: https://httpbin.org/anything
                validation:
                  status: 200
            """
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        let start = Date()
        _ = try rester.expandedRequest("delay").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssert(elapsed > 2, "elapsed time must be larger than delay, was \(elapsed)")
    }

    func test_delay_request_substitution() throws {
        Current.environment = ["DELAY": "2"]
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
        _ = rester.test(before: {_ in}, after: { (name: $0, result: $1) })
            .done { results in
                XCTAssertEqual(results.count, 1)
                XCTAssertEqual(results[0].result, .valid)
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssert(elapsed > 2, "elapsed time must be larger than delay, was \(elapsed)")
    }

    func test_log_request() throws {
        let console = TestConsole()
        Current.console = console
        let s = """
            requests:
              log:
                url: https://httpbin.org/anything
                log: true
            """
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("log").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                // confirm the console receives output
                XCTAssertEqual(console.labels, ["Status", "Headers", "JSON"])
                XCTAssertEqual(console.values[0] as? Int, 200)
                XCTAssert("\(console.values[1])".contains("\"Content-Type\": \"application/json\""))
                XCTAssert("\(console.values[2])".contains("\"method\": \"GET\""))
                expectation.fulfill()
            }.catch {
                XCTFail($0.legibleLocalizedDescription)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}
