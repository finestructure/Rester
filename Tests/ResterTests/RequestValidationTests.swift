//
//  RequestValidationTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 11/04/2019.
//

#if !os(watchOS)

@testable import ResterCore
import XCTest
import Yams


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


class RequestValidationTests: XCTestCase {

    func test_validate_status() async throws {
        let s = try read(fixture: "httpbin.yml")!
        var r = try YAMLDecoder().decode(Restfile.self, from: s)

        do {
            let result = try await r.expandedRequest("status-success").test()
            XCTAssertEqual(result, ValidationResult.valid)
        }

        do {
            let result = try await r.expandedRequest("status-failure").test()
            XCTAssertEqual(result, .invalid("status invalid: (200) is not equal to (500)"))
        }
    }

    func test_validate_json() async throws {
        let s = try read(fixture: "httpbin.yml")!
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)

        do {
            let res = try await rester.expandedRequest("json-success").test()
            XCTAssertEqual(res, ValidationResult.valid)
        }

        do {
            let res = try await rester.expandedRequest("json-failure").test()
            XCTAssertEqual(res, .invalid("json invalid: key \'method\' validation error: (\"GET\") is not equal to (\"nope\")"))
        }

        do {
            let res = try await rester.expandedRequest("json-failure-type").test()
            XCTAssertEqual(res, .invalid("json invalid: key \'method\' validation error: (\"GET\") is not equal to (42)"))
        }
    }

    func test_validate_json_regex() async throws {
        let s = try read(fixture: "httpbin.yml")!
        var rester = try YAMLDecoder().decode(Restfile.self, from: s)

        do {
            let res = try await rester.expandedRequest("json-regex").test()
            XCTAssertEqual(res, ValidationResult.valid)
        }

        do {
            let res = try await rester.expandedRequest("json-regex-failure").test()
            switch res {
                case let .invalid(message):
                    XCTAssert(message.starts(with: "json invalid: key 'uuid' validation error"), "message was: \(message)")
                    XCTAssert(message.ends(with: "does not match (^\\w{8}$)"), "message was: \(message)")
                default:
                    XCTFail("expected failure, received: \(res)")
            }
        }
    }

}

#endif  // !os(watchOS)
