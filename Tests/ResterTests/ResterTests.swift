import XCTest

import AnyCodable
import Yams
@testable import ResterCore


final class ResterTests: XCTestCase {

    func test_decode_variables() throws {
        let s = try readFixture("env.yml")
        let env = try YAMLDecoder().decode(Rester.self, from: s)
        XCTAssertEqual(env.variables!["INT_VALUE"], .int(42))
        XCTAssertEqual(env.variables!["STRING_VALUE"], .string("some string value"))
    }

    func test_subtitute() throws {
      let vars: Variables = ["API_URL": .string("https://foo.bar"), "foo": .int(5)]
      let sub = try _substitute(string: "${API_URL}/baz/${foo}/${foo}", with: vars)
      XCTAssertEqual(sub, "https://foo.bar/baz/5/5")
    }

    func test_version_request() throws {
      let s = try readFixture("version.yml")
      let rest = try YAMLDecoder().decode(Rester.self, from: s)
      let variables = rest.variables!
      let requests = rest.requests!
      let versionReq = try requests["version"]!.substitute(variables: variables)
      XCTAssertEqual(variables["API_URL"]!, .string("https://dev.vbox.space"))
      XCTAssertEqual(versionReq.url, "https://dev.vbox.space/api/metrics/build")
    }

    func test_parse_validation() throws {
        struct Test: Codable {
            let validation: Validation
        }
        let s = """
        validation:
          status: 200
          json:
            version: .regex(\\d+\\.\\d+\\.\\d+|\\S{40})
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.status, 200)
        XCTAssertEqual(t.validation.json!["version"], Matcher.regex("\\d+\\.\\d+\\.\\d+|\\S{40}"))
    }

    func test_request_execute() throws {
        struct Result: Codable { let version: String }

        let s = try readFixture("version.yml")
        let rester = try YAMLDecoder().decode(Rester.self, from: s)
        let variables = rester.variables!
        let requests = rester.requests!
        let versionReq = try requests["version"]!.substitute(variables: variables)

        let expectation = self.expectation(description: #function)

        _ = try versionReq.execute()
            .map {
                XCTAssertEqual($0.response.statusCode, 200)
                let res = try JSONDecoder().decode(Result.self, from: $0.data)
                XCTAssertNotNil(res.version)
                expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func test_rester_execute() throws {
        struct Result: Codable { let version: String }

        let expectation = self.expectation(description: #function)

        let s = try readFixture("version.yml")
        let rester = try YAMLDecoder().decode(Rester.self, from: s)
        _ = try rester.request("version").execute()
            .map {
                XCTAssertEqual($0.response.statusCode, 200)
                let res = try JSONDecoder().decode(Result.self, from: $0.data)
                XCTAssertNotNil(res.version)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func test_validate_status() throws {
        let s = try readFixture("httpbin.yml")
        let rester = try YAMLDecoder().decode(Rester.self, from: s)

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.request("anything").test()
                .map { result in
                    XCTAssertEqual(result, ValidationResult.valid)
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.request("failure").test()
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
            _ = try rester.request("anything").test()
                .map { result in
//                    let res = try JSONDecoder().decode([String: AnyCodable].self, from: $0.data)
//                    XCTAssertEqual(try res["method"]?.assertValue(String.self), "GET")
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
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
