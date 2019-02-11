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

    func test_decodeBasicTypes() throws {
        let s = """
              int: 42
              string: some string value
              stringColon: 'foo: bar'
              double: 3.14
              dict:
                a: 1
                b: two
              array:
                - 1
                - two
                - foo: bar
            """
        struct Test: Decodable {
            let int: Value
            let string: Value
            let stringColon: Value
            let double: Value
            let dict: Value
            let array: Value
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.int, .int(42))
        XCTAssertEqual(t.string, .string("some string value"))
        XCTAssertEqual(t.stringColon, .string("foo: bar"))
        XCTAssertEqual(t.double, .double(3.14))
        XCTAssertEqual(t.dict, .dictionary(["a": .int(1), "b": .string("two")]))
        XCTAssertEqual(t.array, .array([
            .int(1),
            .string("two"),
            .dictionary(["foo": .string("bar")])
            ]))
    }

    func test_encodeBasicTypes() throws {
        struct Test: Encodable {
            let int: Value
            let string: Value
            let stringColon: Value
            let double: Value
            let dict: Value
            let array: Value
        }
        let t = Test(
            int: .int(42),
            string: .string("some string value"),
            stringColon: .string("foo: bar"),
            double: .double(3.14),
            dict: .dictionary(["a": .int(1)]),
            array: .array([
                .int(1),
                .string("two"),
                .dictionary(["foo": .string("bar")])
                ])
        )
        let s = try YAMLEncoder().encode(t)
        XCTAssertEqual(s, """
              int: 42
              string: some string value
              stringColon: 'foo: bar'
              double: 3.14e+0
              dict:
                a: 1
              array:
              - 1
              - two
              - foo: bar

              """)
    }

    func _test_null_yml() throws {
        // Possible bug in Yams
        let s = """
              n1: ~
              n2: null
              n3: NULL
              n4: Null
              n5:
            """
        struct Test: Decodable {
            let n1: String?
            let n2: String?
            let n3: String?
            let n4: String?
            let n5: String?
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertNil(t.n1)  // XCTAssertNil failed: "~"
        XCTAssertNil(t.n2)  // XCTAssertNil failed: "null"
        XCTAssertNil(t.n3)  // XCTAssertNil failed: "NULL"
        XCTAssertNil(t.n4)  // XCTAssertNil failed: "Null"
        XCTAssertNil(t.n5)  // XCTAssertNil failed: ""
    }

    func test_null_json() throws {
        let d = """
            {
                "null": null,
            }
            """.data(using: .utf8)!
        struct Test: Decodable {
            let null: Value
        }
        let res = try? JSONDecoder().decode(Test.self, from: d)
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.null, .null)
    }

    func test_encode_null() throws {
        struct Test: Codable, Equatable {
            let null: Value
        }
        let d = try JSONEncoder().encode(Test(null: .null))
        XCTAssertEqual(String(data: d, encoding: .utf8), "{\"null\":null}")
        let t = try? JSONDecoder().decode(Test.self, from: d)
        XCTAssertEqual(t, Test(null: .null))
    }

    func test_bool_json() throws {
        let d = """
            {
                "flag1": true,
                "flag2": false
            }
            """.data(using: .utf8)!
        struct Test: Decodable {
            let flag1: Value
            let flag2: Value
        }
        let res = try? JSONDecoder().decode(Test.self, from: d)
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.flag1, true)
        XCTAssertEqual(res?.flag2, false)
    }

    func test_decodeComplexResponse() throws {
        do {
            let d = """
            {
                "args": {},
                "data": "",
                "files": {},
                "form": {},
                "headers": {
                    "Accept": "*/*",
                    "Accept-Encoding": "gzip, deflate",
                    "Connection": "close",
                    "Host": "httpbin.org",
                    "User-Agent": "HTTPie/1.0.2"
                },
                "json": null,
                "method": "GET",
                "origin": "212.225.161.191",
                "url": "https://httpbin.org/anything"
            }
            """.data(using: .utf8)!
            let res = try? JSONDecoder().decode([Key: Value?].self, from: d)
            XCTAssertNotNil(res)
        }
    }


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

}
