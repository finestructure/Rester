//
//  RequestValidationTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 11/04/2019.
//

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

    func test_validate_status() throws {
        let s = try read(fixture: "httpbin.yml")!
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
                    XCTAssertEqual(result, .invalid("status invalid: (200) is not equal to (500)"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func test_validate_json() throws {
        let s = try read(fixture: "httpbin.yml")!
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
                    XCTAssertEqual($0, .invalid("json invalid: key \'method\' validation error: (\"GET\") is not equal to (\"nope\")"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }

        do {
            let expectation = self.expectation(description: #function)
            _ = try rester.expandedRequest("json-failure-type").test()
                .map {
                    XCTAssertEqual($0, .invalid("json invalid: key \'method\' validation error: (\"GET\") is not equal to (42)"))
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

    func test_validate_json_regex() throws {
        let s = try read(fixture: "httpbin.yml")!
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
                    case let .invalid(message):
                        XCTAssert(message.starts(with: "json invalid: key 'uuid' validation error"), "message was: \(message)")
                        XCTAssert(message.ends(with: "does not match (^\\w{8}$)"), "message was: \(message)")
                    }
                    expectation.fulfill()
            }
            waitForExpectations(timeout: 5)
        }
    }

}
