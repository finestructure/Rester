//
//  ValueTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 27/01/2019.
//

#if !os(watchOS)

import XCTest
@testable import ResterCore

import Path
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

    func test_path() throws {
        XCTAssertEqual(try Value.string(".file(foo.txt)").path(), Current.workDir/"foo.txt")

        XCTAssertThrowsError(try Value.string("test.jpg").path()) { error in
            XCTAssertEqual(error.legibleLocalizedDescription, "internal error: expected to find .file(...) attribute")
        }

        // TODO: add test for path with spaces and parenthesis
    }

    func test_isJSONReference() throws {
        XCTAssert(Value.string("json.foo").isJSONReference)
        XCTAssert(Value.string("json[0].foo").isJSONReference)
        XCTAssert(!Value.bool(true).isJSONReference)
    }

    func test_appendValue() throws {
        XCTAssertEqual(Value.string(".append(foo)").appendValue, "foo")
        XCTAssertEqual(Value.string("foo").appendValue, nil)
        XCTAssertEqual(Value.bool(true).appendValue, nil)
    }

    func test_removeValue() throws {
        XCTAssertEqual(Value.string(".remove(foo)").removeValue, "foo")
        XCTAssertEqual(Value.string("foo").removeValue, nil)
        XCTAssertEqual(Value.bool(true).removeValue, nil)
    }

}

#endif  // !os(watchOS)
