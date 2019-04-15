//
//  ResponseTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 15/04/2019.
//

@testable import ResterCore
import XCTest


class ResponseTests: XCTestCase {

    func test_resolve() throws {
        let vars: [Key: Value] = ["foo": "json.method"]
        let json: Value? = ["method": "GET"]
        XCTAssertEqual(try resolve(variables: vars, json: json), ["method": "GET", "foo": "GET"])
    }

    func test_resolve_json_array() throws {
        // implement me
    }

}
