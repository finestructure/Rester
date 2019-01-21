import XCTest

import Yams
@testable import ResterCore


struct Top: Decodable {
    let requests: Requests
}

struct Requests: Decodable {
    let items: [[String: Int]]
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderedCodingKeys.self)
        self.items = try container.decodeOrdered(Int.self)
    }
}

struct OrderedCodingKeys: CodingKey {
    var intValue: Int?
    var stringValue: String

    init?(intValue: Int) {
        return nil
    }

    init?(stringValue: String){
        self.stringValue = stringValue
    }
}

extension KeyedDecodingContainer where Key == OrderedCodingKeys {
    func decodeOrdered<T: Decodable>(_ type: T.Type) throws -> [[String: T]] {
        var data = [[String: T]]()

        for key in allKeys {
            let value = try decode(T.self, forKey: key)
            data.append([key.stringValue: value])
        }

        return data
    }
}



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
        struct Test: Decodable {
            let validation: Validation
        }
        let s = """
        validation:
          status: 200
          json:
            int: 42
            string: foo
            regex: .regex(\\d+\\.\\d+\\.\\d+|\\S{40})
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.status, 200)
        XCTAssertEqual(t.validation.json!["int"], Matcher.int(42))
        XCTAssertEqual(t.validation.json!["string"], Matcher.string("foo"))
        XCTAssertEqual(t.validation.json!["regex"], Matcher.regex("\\d+\\.\\d+\\.\\d+|\\S{40}".r!))
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
            _ = try rester.request("json-success").test()
                .map {
                    XCTAssertEqual($0, ValidationResult.valid)
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.request("json-failure").test()
                .map {
                    XCTAssertEqual($0, ValidationResult.invalid("json.method invalid, expected 'nope' was 'GET'"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.request("json-failure-type").test()
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
            _ = try rester.request("json-regex").test()
                .map {
                    XCTAssertEqual($0, ValidationResult.valid)
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.request("json-regex-failure").test()
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

    func test_order() throws {
        let s = """
        requests:
          a: 1
          b: 2
          c: 3
          d: 4
        """
        let d = try YAMLDecoder().decode(Top.self, from: s)
        XCTAssertEqual(Array(d.requests.items), [["a": 1], ["b": 2], ["c": 3], ["d": 4]])
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
