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
        let req = try requests["basic"]!.substitute(variables: variables)
        XCTAssertEqual(variables["API_URL"]!, .string("https://httpbin.org"))
        XCTAssertEqual(req.details.url, "https://httpbin.org/anything")
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
        do {
            let rest = try YAMLDecoder().decode(Restfile.self, from: s, userInfo: [.relativePath: workDir])
            let rfs = rest.restfiles
            XCTAssertEqual(rfs?.count, 3)
            XCTAssertEqual(rfs?.first?.variables, ["API_URL": "https://httpbin.org"])
            XCTAssertEqual(rfs?.last?.requests?.map { $0.name }, ["basic2"])

            XCTAssertNil(rest.requests, "top level file has no requests")
        }

        do {
            // TODO: more to ResterTests
            let r = try Rester(yml: s, workDir: workDir)
            XCTAssertEqual(r.allRequests.count, 2)
            XCTAssertEqual(r.allVariables, ["API_URL": "https://httpbin.org"])
            XCTAssertEqual(r.allRequests.map { $0.name }, ["basic", "basic2"])
        }
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

    func test_parse_complex_form() throws {
        let s = """
            variables:
              api_url: https://httpbin.org
              client_id: 8a8099f9-8149-4039-a3fd-59ad69330038
              email_username: foo.bar.baz
              email_domain: example.com
              password: "29%x)(+&id28xY%f42cq"
            requests:
              login:
                url: ${api_url}/anything
                method: POST
                body:
                  form:
                    grant_type: password
                    scope: read:user write:user
                    client_id: ${client_id}
                    username: ${email_username}@${email_domain}
                    password: ${password}
            """
        let rest = try YAMLDecoder().decode(Restfile.self, from: s)
        guard let variables = rest.variables else {
            XCTFail("variables must not be nil")
            return
        }
        guard let requests = rest.requests else {
            XCTFail("requests must not be nil")
            return
        }

        XCTAssertEqual(variables["api_url"], "https://httpbin.org")
        XCTAssertEqual(variables["client_id"], "8a8099f9-8149-4039-a3fd-59ad69330038")
        XCTAssertEqual(variables["email_username"], "foo.bar.baz")
        XCTAssertEqual(variables["email_domain"], "example.com")
        XCTAssertEqual(variables["password"], "29%x)(+&id28xY%f42cq")

        let req = try requests["login"]?.substitute(variables: variables)
        XCTAssertEqual(req?.details.url, "https://httpbin.org/anything")

        let expandedBody = try req?.body?.substitute(variables: variables)
        XCTAssertEqual(expandedBody?.form?["grant_type"], "password")
        XCTAssertEqual(expandedBody?.form?["scope"], "read:user write:user")
        XCTAssertEqual(expandedBody?.form?["client_id"], "8a8099f9-8149-4039-a3fd-59ad69330038")
        XCTAssertEqual(expandedBody?.form?["username"], "foo.bar.baz@example.com")
        XCTAssertEqual(expandedBody?.form?["password"], "29%x)(+&id28xY%f42cq")

        guard let encodedForm = expandedBody?.form?.formUrlEncoded else {
            XCTFail("encoded form must not be nil")
            return
        }
        XCTAssert(encodedForm.contains("username=foo.bar.baz%40example.com"), "was: \(encodedForm)")
    }

}
