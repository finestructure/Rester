import XCTest

import Path
import Yams
@testable import ResterCore


#if !os(watchOS)

class RestfileTests: XCTestCase {

    func test_decode_variables() throws {
        let s = """
            variables:
              INT_VALUE: 42
              STRING_VALUE: some string value
            """
        let env = try YAMLDecoder().decode(Restfile.self, from: s)
        XCTAssertEqual(env.variables["INT_VALUE"], .int(42))
        XCTAssertEqual(env.variables["STRING_VALUE"], .string("some string value"))
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
        let variables = rest.variables
        let requests = rest.requests
        let req = try requests["basic"]!.substitute(variables: variables)
        XCTAssertEqual(variables["API_URL"]!, .string("https://httpbin.org"))
        XCTAssertEqual(req.details.url, "https://httpbin.org/anything")
    }

    func test_parse_malformed_request() throws {
        let s = """
            requests:
              basic:
                request:  # this key is unexpected
                  url: https://httpbin.org/anything  # as is this indentation
            """
        XCTAssertThrowsError(try YAMLDecoder().decode(Restfile.self, from: s)) { error in
            XCTAssertNotNil(error as? DecodingError)
            if
                let decodingError = error as? DecodingError,
                case let .dataCorrupted(err) = decodingError,
                let underlying = err.underlyingError as? ResterError,
                case let .keyNotFound(key) = underlying {

                XCTAssertEqual(key, "url")
            } else {
                XCTFail("expected .keyNotFound exception, found: \(error)")
            }
        }
    }

    func test_parse_malformed_validation() throws {
        let s = """
            requests:
              basic:
                url: https://httpbin.org/anything
                validation:
                  statuc: 200  # mistyped attribute
            """
        XCTAssertThrowsError(try YAMLDecoder().decode(Restfile.self, from: s)) { error in
            XCTAssertNotNil(error as? DecodingError)
            if
                let decodingError = error as? DecodingError,
                case let .dataCorrupted(err) = decodingError,
                let underlying = err.underlyingError as? ResterError,
                case let .unexpectedKeyFound(key) = underlying {

                XCTAssertEqual(key, "statuc")
            } else {
                XCTFail("expected .unexpectedKeyFound exception, found: \(error)")
            }
        }
    }

    func test_parse_request_order() throws {
        let s = """
            requests:
              r_3:
                url: https://httpbin.org/anything
              r_2:
                url: https://httpbin.org/anything
              r_1:
                url: https://httpbin.org/anything
              r_a:
                url: https://httpbin.org/anything
              r_b:
                url: https://httpbin.org/anything
              r_c:
                url: https://httpbin.org/anything
            """
        let rest = try YAMLDecoder().decode(Restfile.self, from: s)
        let names = rest.requests.map { $0.name }
        XCTAssertEqual(names, ["r_3", "r_2", "r_1", "r_a", "r_b", "r_c"])
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

    func test_parse_body_multipart() throws {
        struct Test: Decodable {
            let body: Body
        }
        let s = """
            body:
              multipart:
                foo: bar
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.body.multipart?["foo"], Value.string("bar"))
    }

    func test_parse_body_text() throws {
        struct Test: Decodable {
            let body: Body
        }
        let s = """
            body:
              text: foobar
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.body.text, "foobar")
    }

    func test_parse_body_file() throws {
        struct Test: Decodable {
            let body: Body
        }
        let s = """
            body:
              file: f.png
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.body.file, "f.png")
    }

    func test_Restfile_init() throws {
        let workDir = examplesDirectory()!
        let r = try Restfile(path: workDir/"basic.yml")
        XCTAssertEqual(r.requests.map { $0.name }, ["basic"])
    }

    func test_parse_restfiles_basic() throws {
        let workDir = examplesDirectory()!

        let s = """
            restfiles:
              - batch/env.yml
              - batch/basic.yml
              - batch/basic2.yml
        """

        let rest = try YAMLDecoder().decode(Restfile.self, from: s, userInfo: [.relativePath: workDir])
        let rfs = rest.restfiles
        XCTAssertEqual(rfs.count, 3)
        XCTAssertEqual(rfs.first?.variables, ["API_URL": "https://httpbin.org"])
        XCTAssertEqual(rfs.last?.requests.map { $0.name }, ["basic2"])
        XCTAssert(rest.requests.isEmpty, "top level file has no requests")
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
                XCTFail("expected .fileNotFound exception, found: \(error)")
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
        let rf = try YAMLDecoder().decode(Restfile.self, from: s)

        XCTAssertEqual(rf.variables["api_url"], "https://httpbin.org")
        XCTAssertEqual(rf.variables["client_id"], "8a8099f9-8149-4039-a3fd-59ad69330038")
        XCTAssertEqual(rf.variables["email_username"], "foo.bar.baz")
        XCTAssertEqual(rf.variables["email_domain"], "example.com")
        XCTAssertEqual(rf.variables["password"], "29%x)(+&id28xY%f42cq")

        let req = try rf.requests["login"]?.substitute(variables: rf.variables)
        XCTAssertEqual(req?.details.url, "https://httpbin.org/anything")

        let expandedBody = try req?.body?.substitute(variables: rf.variables)
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

    func test_parse_set_up() throws {
        let s = """
            set_up:
              basic:
                url: https://httpbin.org/anything
                validation:
                  status: 200
            """
        let rest = try YAMLDecoder().decode(Restfile.self, from: s)
        XCTAssertEqual(rest.setupRequests["basic"]?.details.url, "https://httpbin.org/anything")
    }

    func test_parse_mode() throws {
        do {  // explicit
            let s = """
                mode: random
                """
            let rest = try YAMLDecoder().decode(Restfile.self, from: s)
            XCTAssertEqual(rest.mode, .random)
        }
        do {  // default
            let s = """
                requests:
                  r1:
                    url: http://foo.bar
                """
            let rest = try YAMLDecoder().decode(Restfile.self, from: s)
            XCTAssertEqual(rest.mode, .sequential)
        }
    }

}

#endif  // !os(watchOS)
