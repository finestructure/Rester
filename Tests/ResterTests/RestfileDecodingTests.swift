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

    func test_parse_restfiles_basic() throws {
        let s = """
            restfiles:
              - env.yml
              - nested/basic.yml
        """
        struct Test: Decodable {
            let restfiles: [Path]
        }
        let tdd = testDataDirectory()!
        let t = try YAMLDecoder().decode(Test.self, from: s, userInfo: [.relativePath: tdd])
        XCTAssertEqual(t.restfiles, [tdd/"env.yml", tdd/"nested/basic.yml"])
        XCTAssertEqual(t.restfiles.map { $0.exists }, [true, true])
    }

    func test_Restfile_init() throws {
        let workDir = testDataDirectory()!
        let r = try Restfile(path: workDir/"nested/basic.yml")
        XCTAssertEqual(r.requests?.map { $0.name }, ["basic"])
    }

    func test_parse_restfiles_Restfile() throws {
        let workDir = testDataDirectory()!

        let s = """
            restfiles:
              - env.yml
              - nested/basic.yml
        """
        let rest = try YAMLDecoder().decode(Restfile.self, from: s, userInfo: [.relativePath: workDir])
        let rfs = try rest.restfiles?.map { try Restfile(path: $0) }
        XCTAssertEqual(rfs?.count, 2)
        XCTAssertEqual(rfs?.first?.variables, ["API_URL": "https://httpbin.org"])
        XCTAssertEqual(rfs?.last?.requests?.map { $0.name }, ["basic"])

        // FIXME: feed aggregated variables into expandedRequests
        XCTAssertEqual(try rest.expandedRequests().count, 1)
    }

}
