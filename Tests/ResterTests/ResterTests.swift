import XCTest
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
          content:
            version: .regex(\\d+\\.\\d+\\.\\d+|\\S{40})
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.status, 200)
        XCTAssertEqual(t.validation.content!["version"], Matcher.regex("\\d+\\.\\d+\\.\\d+|\\S{40}"))
    }

    func test_request() throws {
        let expectation = self.expectation(description: #function)
        var status: Int?
        struct Result: Codable {
            let version: String
        }
        var result: Result?

        let s = try readFixture("version.yml")
        let rest = try YAMLDecoder().decode(Rester.self, from: s)
        let variables = rest.variables!
        let requests = rest.requests!
        let versionReq = try requests["version"]!.substitute(variables: variables)

        versionReq.execute { (data, response, error) in
            if let error = error {
                XCTFail("error: \(error)")
            } else {
                if let response = response as? HTTPURLResponse {
                    status = response.statusCode
                }
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    result = try? YAMLDecoder().decode(Result.self, from: string)
                }
            }
            expectation.fulfill()
            }
        waitForExpectations(timeout: 5)
        XCTAssertEqual(status, 200)
        XCTAssertNotNil(result?.version)
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
