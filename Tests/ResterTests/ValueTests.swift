//
//  ValueTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 27/01/2019.
//

import XCTest
@testable import ResterCore

import Yams


class ValueTests: XCTestCase {

    func test_formUrlEncoded() throws {
        do {
            let d: [Key: Value] = ["foo": "bar"]
            XCTAssertEqual(d.formUrlEncoded, "foo=bar")
        }
        do {
            let d: [Key: Value] = ["data": "test/test=42"]
            XCTAssertEqual(d.formUrlEncoded, "data=test%2Ftest=42")
        }
        do {
            let d: [Key: Value] = ["email": "innogy.vbox.test+smoke-test@gmail.com"]
            XCTAssertEqual(d.formUrlEncoded, "email=innogy.vbox.test%2Bsmoke-test%40gmail.com")
        }
        do {
            let d: [Key: Value] = ["a": "1", "b": 2]
            XCTAssert(["a=1&b=2", "b=2&a=1"].contains(d.formUrlEncoded), "was: \(d.formUrlEncoded)")
        }
    }

    func test_multipartEncoded() throws {
        do {
            let d: [Key: Value] = ["foo2": "baz", "foo1": "bar"]
            XCTAssertEqual(
                String(data: try d.multipartEncoded(), encoding: .utf8),
                """
                --__X_RESTER_BOUNDARY__
                Content-Disposition: form-data; name="foo1"

                bar
                --__X_RESTER_BOUNDARY__
                Content-Disposition: form-data; name="foo2"

                baz
                --__X_RESTER_BOUNDARY__--
                """
            )
        }
    }

    func test_key_substitution() throws {
        let d: Value = .dictionary(["foo": "bar"])
        let a: Value = .array(["a", 42, d])
        let response: [Request.Name: Value] = ["request": a]
        do { // legacy indexing syntax
            let value: Value = "${request.2.foo}"
            XCTAssertEqual(try value.substitute(variables: response), "bar")
        }
        do { // recommended indexing syntax
            let value: Value = "${request[2].foo}"
            XCTAssertEqual(try value.substitute(variables: response), "bar")
        }
    }

}
