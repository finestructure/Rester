import XCTest

import AnyCodable
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
        guard let req = requests?[requestName]
            else { throw ResterError.noSuchRequest(requestName) }
        let aggregatedVariables = aggregate(variables: variables, from: restfiles)
        return try req.substitute(variables: aggregatedVariables)
    }
}


final class RestfileRequestTests: XCTestCase {

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
                    case let .invalid(message, response: _):
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
        let names = rester.requests?.map { $0.name }
        XCTAssertEqual(names, ["first", "second", "3rd"])
    }

    // TODO: move test
    func test_launch_binary() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("rester")
        let requestFile = path(for: "basic.yml")!

        let process = Process()
        process.executableURL = binary
        process.arguments = [requestFile.string]

        let pipe = Pipe()
        process.standardOutput = pipe

        #if os(Linux)
        process.launch()
        #else
        try process.run()
        #endif
        
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        let status = process.terminationStatus

        XCTAssert(
            output?.starts(with: "🚀  Resting") ?? false,
            "output start does not match, was: \(output ?? "")"
        )
        XCTAssert(
            status == 0,
            "exit status not 0, was: \(status), output: \(output ?? "")"
        )
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

    // TODO: move to ResterTests
    func test_response_variable() throws {
        let s = """
            variables:
              api_url: https://dev.vbox.space/api
              ios_client_id: 48e148ed-fa59-43c6-ac98-f8a8700fff5c
              email_username: innogy.vbox.test
              email_domain: gmail.com
              password: dev-junction-ripen-upsilon-oakwood
            requests:
              login:
                url: ${api_url}/oauth2/token
                method: POST
                body:
                  form:
                    grant_type: password
                    scope: read:user write:user
                    client_id: ${ios_client_id}
                    username: ${email_username}@${email_domain}
                    password: ${password}
                validation:
                  status: 200
                  json:
                    access_token: .regex(.{30})
              user_me:
                url: ${api_url}/v1/user/me
                headers:
                  Authorization: Bearer ${login.json.access_token}
                validation:
                  status: 200
            """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, result: $1) })
            .done { results in
                XCTAssertEqual(results.count, 2)
                XCTAssertEqual(results[0].name, "login")
                XCTAssertEqual(results[0].result, .valid)
                XCTAssertEqual(results[1].name, "user_me")
                XCTAssertEqual(results[1].result, .valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_validate_json_array() throws {
        let s = """
            variables:
              api_url: https://dev.vbox.space/api
              ios_client_id: 48e148ed-fa59-43c6-ac98-f8a8700fff5c
              email_username: innogy.vbox.test
              email_domain: gmail.com
              password: dev-junction-ripen-upsilon-oakwood
            requests:
              login:
                url: ${api_url}/oauth2/token
                method: POST
                body:
                  form:
                    grant_type: password
                    scope: read:user write:user
                    client_id: ${ios_client_id}
                    username: ${email_username}@${email_domain}
                    password: ${password}
                validation:
                  status: 200
                  json:
                    access_token: .regex(.{30})

              provider_list:
                url: ${api_url}/v1/provider
                headers:
                  Authorization: Bearer ${login.json.access_token}
                query:
                  sort_by: name
                  provider_type: preset
                validation:
                  status: 200
                  json:
                    0:
                      name: 1&1 Internet
        """
        let r = try Rester(yml: s)
        let expectation = self.expectation(description: #function)
        _ = r.test(before: {_ in }, after: { (name: $0, result: $1) })
            .done { results in
                XCTAssertEqual(results.count, 2)
                XCTAssertEqual(results[0].name, "login")
                XCTAssertEqual(results[0].result, .valid)
                XCTAssertEqual(results[1].name, "provider_list")
                XCTAssertEqual(results[1].result, .valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

}
