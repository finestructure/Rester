import XCTest

import Path
import Yams
@testable import ResterCore


class RestfileDecodingTests: XCTestCase {

    func test_decode_variables() throws {
        let s = """
            variables:
              INT_VALUE: 42
              STRING_VALUE: some string value
            """
        let env = try YAMLDecoder().decode(Restfile.self, from: s)
        XCTAssertEqual(env.variables!["INT_VALUE"], .int(42))
        XCTAssertEqual(env.variables!["STRING_VALUE"], .string("some string value"))
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
        let rest = try YAMLDecoder().decode(Restfile.self, from: s)
        let variables = rest.variables!
        let requests = rest.requests!
        let versionReq = try requests["basic"]!.substitute(variables: variables)
        XCTAssertEqual(variables["API_URL"]!, .string("https://httpbin.org"))
        XCTAssertEqual(versionReq.url, "https://httpbin.org/anything")
    }

    func test_parse_body_json() throws {
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

    func test_parse_body_form() throws {
        struct Test: Decodable {
            let body: Body
        }
        let s = """
            body:
              form:
                foo: bar
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.body.form?["foo"], Value.string("bar"))
    }

    func test_Restfile_init() throws {
        let workDir = testDataDirectory()!
        let r = try Restfile(path: workDir/"nested/basic.yml")
        XCTAssertEqual(r.requests?.map { $0.name }, ["basic"])
    }

    func test_parse_restfiles_basic() throws {
        let workDir = testDataDirectory()!

        let s = """
            restfiles:
              - env.yml
              - nested/basic.yml
              - nested/basic2.yml
        """
        let rest = try YAMLDecoder().decode(Restfile.self, from: s, userInfo: [.relativePath: workDir])
        let rfs = rest.restfiles
        XCTAssertEqual(rfs?.count, 3)
        XCTAssertEqual(rfs?.first?.variables, ["API_URL": "https://httpbin.org"])
        XCTAssertEqual(rfs?.last?.requests?.map { $0.name }, ["basic2"])

        XCTAssertEqual(rest.requestCount, 2)
        XCTAssertEqual(rest.aggregatedVariables, ["API_URL": "https://httpbin.org"])
        XCTAssertEqual(rest.aggregatedRequests.map { $0.name }, ["basic", "basic2"])

        XCTAssertEqual(try rest.expandedRequests().count, 2)
    }

    func test_parse_restfiles_invalid_path() throws {
        let workDir = testDataDirectory()!

        let s = """
            restfiles:
              - does_not_exist
        """
        XCTAssertThrowsError(
            try YAMLDecoder().decode(Restfile.self, from: s, userInfo: [.relativePath: workDir])
        ) { error in
            XCTAssertNotNil(error as? DecodingError)
            if
                let decodingError = error as? DecodingError,
                case let .dataCorrupted(err) = decodingError,
                let underlying = err.underlyingError as? ResterError,
                case let .fileNotFound(path) = underlying {

                XCTAssert(path.ends(with: "does_not_exist"), "wrong path, was: \(path)")
            } else {
                XCTFail("expected file not found exception, found: \(error)")
            }
        }
    }

}
