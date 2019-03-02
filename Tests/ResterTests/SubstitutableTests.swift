//
//  GlobalTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 31/01/2019.
//

import XCTest

@testable import ResterCore
import ValueCodable


class SubstitutableTests: XCTestCase {

    func test_substitute() throws {
        let vars: [Key: Value] = ["API_URL": .string("https://foo.bar"), "foo": .int(5)]
        let sub = try substitute(string: "${API_URL}/baz/${foo}/${foo}", with: vars)
        XCTAssertEqual(sub, "https://foo.bar/baz/5/5")
    }

    func test_substitute_Body() throws {
        let vars: [Key: Value] = ["a": "1", "b": 2]
        let body = Body(json: ["data": "json field: ${a} ${b}"], form: ["data": "form field: ${a} ${b}"])
        let expanded = try body.substitute(variables: vars)
        XCTAssertEqual(expanded.json, ["data": "json field: 1 2"])
        XCTAssertEqual(expanded.form, ["data": "form field: 1 2"])
    }
    
}
