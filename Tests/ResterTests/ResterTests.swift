import XCTest

import AnyCodable
import PromiseKit
import Yams
@testable import ResterCore


final class ResterTests: XCTestCase {

    func test_decode_variables() throws {
        let s = """
            variables:
              INT_VALUE: 42
              STRING_VALUE: some string value
            """
        let env = try YAMLDecoder().decode(Rester.self, from: s)
        XCTAssertEqual(env.variables!["INT_VALUE"], .int(42))
        XCTAssertEqual(env.variables!["STRING_VALUE"], .string("some string value"))
    }

    func test_subtitute() throws {
        let vars: Variables = ["API_URL": .string("https://foo.bar"), "foo": .int(5)]
        let sub = try _substitute(string: "${API_URL}/baz/${foo}/${foo}", with: vars)
        XCTAssertEqual(sub, "https://foo.bar/baz/5/5")
    }

    func test_parse_basic() throws {
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
        let rest = try YAMLDecoder().decode(Rester.self, from: s)
        let variables = rest.variables!
        let requests = rest.requests!
        let versionReq = try requests["basic"]!.substitute(variables: variables)
        XCTAssertEqual(variables["API_URL"]!, .string("https://httpbin.org"))
        XCTAssertEqual(versionReq.url, "https://httpbin.org/anything")
    }

    func test_parse_body() throws {
        struct Test: Decodable {
            let body: Body
        }
        let s = """
            body:
              json:
                foo: bar
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.body.json?["foo"], Value.string("bar"))
    }

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
        let rester = try YAMLDecoder().decode(Rester.self, from: s)

        let expectation = self.expectation(description: #function)

        _ = try rester.expandedRequest("basic").execute()
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
        let s = try readFixture("httpbin.yml")
        let rester = try YAMLDecoder().decode(Rester.self, from: s)

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("status-success").test()
                .map { result in
                    XCTAssertEqual(result, ValidationResult.valid)
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("status-failure").test()
                .map { result in
                    XCTAssertEqual(result, ValidationResult.invalid("status invalid, expected '500' was '200'"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func test_validate_json() throws {
        let s = try readFixture("httpbin.yml")
        let rester = try YAMLDecoder().decode(Rester.self, from: s)

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
                    XCTAssertEqual($0, ValidationResult.invalid("json.method invalid, expected 'nope' was 'GET'"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-failure-type").test()
                .map {
                    XCTAssertEqual($0, ValidationResult.invalid("json.method expected to be of type Int, was 'GET'"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func test_validate_json_regex() throws {
        let s = try readFixture("httpbin.yml")
        let rester = try YAMLDecoder().decode(Rester.self, from: s)

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
                    case .invalid(let message):
                        XCTAssert(message.starts(with: "json.uuid failed to match \'^\\w{8}$\'"))
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
        let rester = try YAMLDecoder().decode(Rester.self, from: s)
        let names = rester.requests?.names
        XCTAssertEqual(names, ["first", "second", "3rd"])
    }

    func test_launch_binary() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("rester")
        let requestFile = url(for: "basic.yml").path

        let process = Process()
        process.executableURL = binary
        process.arguments = [requestFile]

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

    func test_post_request() throws {
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
        let rester = try YAMLDecoder().decode(Rester.self, from: s)
        let expectation = self.expectation(description: #function)
        _ = try rester.expandedRequest("post").test()
            .map {
                XCTAssertEqual($0, ValidationResult.valid)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_anycodable_dict() throws {
        struct Test: Decodable {
            let dict: AnyCodable
        }
        let s = """
            dict:
                foo: bar
        """
        let t = try? YAMLDecoder().decode(Test.self, from: s)
        XCTAssertNotNil(t)
        let anyDict = try? t?.dict.assertValue([String: AnyCodable].self)
        XCTAssertNotNil(anyDict)   // <- fails. This is the issue with matching the json object in
        // Request.swift:140
        // guard let foundObject = try? found.assertValue([Key: AnyCodable].self) else {
        // where the guard triggers and bails out of validation
        let stringDict = try? t?.dict.assertValue([String: String].self)
        XCTAssertNotNil(stringDict)
    }
}


func url(for fixture: String, path: String = #file) -> URL {
  let testDir = URL(fileURLWithPath: path).deletingLastPathComponent()
  return testDir.appendingPathComponent("TestData/\(fixture)")
}


func readFixture(_ fixture: String, path: String = #file) throws -> String {
  let file = url(for: fixture)
  return try String(contentsOf: file)
}

var productsDirectory: URL {
    #if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
    }
    fatalError("couldn't find the products directory")
    #else
    return Bundle.main.bundleURL
    #endif
}
