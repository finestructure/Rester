import XCTest

import LegibleError
import PromiseKit
import Rainbow
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
                    XCTAssertEqual(result, .invalid("status invalid: (200) is not equal to (500)"))
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
                    XCTAssertEqual($0, .invalid("json invalid: key \'method\' validation error: (\"GET\") is not equal to (\"nope\")"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-failure-type").test()
                .map {
                    XCTAssertEqual($0, .invalid("json invalid: key \'method\' validation error: (\"GET\") is not equal to (42)"))
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
                    case let .invalid(message):
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

    func test_post_json() throws {
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

    func test_post_form() throws {
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

    func test_post_multipart() throws {
        let testFile = path(for: "test.jpg")!
        let s = """
            requests:
              post:
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
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("post").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_post_text() throws {
        let s = """
            requests:
              post:
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
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("post").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

     func test_post_file() throws {
         let testFile = path(for: "test.jpg")!
         let s = """
             requests:
               post:
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
        let console = TestConsole()
        Current.console = console
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

    func test_delay_request_substitution() throws {
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

    func test_log_request_json_keypath() throws {
        let console = TestConsole()
        Current.console = console
        let s = """
            requests:
              log:
                url: https://httpbin.org/anything
                log:
                  - json.headers.Host
            """
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("log").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                // confirm the console receives output
                // we're expecting the value pulled from the key path `headers.Host` in the json response
                XCTAssertEqual(console.labels, ["headers.Host"])
                XCTAssertEqual(console.values.first as? Value?, "httpbin.org")
                expectation.fulfill()
            }.catch {
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
