//
//  ValidationTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 27/01/2019.
//

import XCTest
@testable import ResterCore

import Regex
import Yams


extension Matcher {
    var contains: [Key: Matcher]? {
        switch self {
        case .contains(let dict):
            return dict
        default:
            return nil
        }
    }
}


class ValidationTests: XCTestCase {

    func test_convertMatcher() throws {
        let int = Value.int(200)
        let double = Value.double(3.14)
        let string = Value.string("a")
        let array = Value.array([int, string])
        XCTAssertEqual(try Matcher(value: int), .equals(int))
        XCTAssertEqual(try Matcher(value: double), .equals(double))
        XCTAssertEqual(try Matcher(value: string), .equals(string))
        XCTAssertEqual(try Matcher(value: array), .equals(array))

        let regex = Value.string(".regex(.*)")
        XCTAssertEqual(try Matcher(value: regex), .regex(".*".r!))

        let dict = Value.dictionary(["foo" : .string("bar")])
        XCTAssertEqual(try Matcher(value: dict), .contains(["foo" : .equals("bar")]))
    }

    func test_parse_Validation() throws {
        struct Test: Decodable {
            let validation: Validation
        }
        let s = """
        validation:
          status: 200
          json:
            int: 42
            string: foo
            regex: .regex(.*)
            object:
              foo: bar
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.status, .equals(.int(200)))
        let containing = t.validation.json?.contains
        XCTAssertNotNil(containing)
        XCTAssertEqual(containing?["int"], .equals(.int(42)))
        XCTAssertEqual(containing?["string"], .equals(.string("foo")))
        XCTAssertEqual(containing?["regex"], .regex(".*".r!))
        XCTAssertEqual(containing?["object"], .contains(["foo": .equals("bar")]))
    }

    func test_validate() throws {
        XCTAssertEqual(try Matcher(200).validate(200), .valid)
        XCTAssertEqual(try Matcher(200).validate(404), .init(invalid: "(404) is not equal to (200)"))
        XCTAssertEqual(try Matcher("foo").validate("foo"), .valid)
        XCTAssertEqual(try Matcher(200).validate("foo"), .init(invalid: "(\"foo\") is not equal to (200)"))
        XCTAssertEqual(try Matcher(200).validate("200"), .init(invalid: "(\"200\") is not equal to (200)"))

        XCTAssertEqual(try Matcher(".regex(\\d\\d)").validate("foo42"), .valid)
        XCTAssertEqual(try Matcher(".regex(\\d\\d)").validate("foo"), .init(invalid: "(foo) does not match (\\d\\d)"))

        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar"]), .valid)
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["nope": "-"]), .init(invalid: "key \'foo\' not found in \'[\"nope\": \"-\"]\'"))
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "-"]), .init(invalid: "key \'foo\' validation error: (\"-\") is not equal to (\"bar\")"))
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar", "extra": "value"]), .valid)
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar", "mixed_type": 1]), .valid)
    }

    func test_parse_json_array() throws {
        struct Test: Decodable {
            let validation: Validation
        }
        let s = """
        validation:
          status: 200
          json:
            0:
              foo: bar
            1: value1
            -1: 42
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.json,
                       .contains([
                        "0": .contains(["foo": .equals("bar")]),
                        "1": .equals("value1"),
                        "-1": .equals(42)
                        ])
        )
    }

    func test_validate_json_array() throws {
        do {  // test success
            let matcher: Matcher = .contains([
                "0": .contains(["foo": .equals("bar")]),
                "1": .equals("value1"),
                "-1": .equals(42)
                ])
            let response: Value = .array([
                ["foo": "bar", "baz": 42],
                "value1",
                "random",
                42
                ])
            XCTAssertEqual(matcher.validate(response), .valid)
        }
        do {  // test failure
            let matcher: Matcher = .contains([
                "0": .contains(["foo": .equals("bar")]),
                ])
            let response: Value = .array([["nope": "-"]])
            XCTAssertEqual(matcher.validate(response),
                           .invalid("index \'0\' validation error: key \'foo\' not found in \'[\"nope\": \"-\"]\'", response: nil))
        }
    }

    func test_Matcher_substitute() throws {
        let vars: [Key: Value] = ["test": "resolved"]
        XCTAssertEqual(try Matcher(value: "${test}").substitute(variables: vars),
                       .equals("resolved"))
        XCTAssertEqual(try Matcher(value: ["data": "${test}"]).substitute(variables: vars),
                       .contains(["data": .equals("resolved")]))
    }

    func test_Validation_substitute() throws {
        let validation = Validation(status: nil, headers: nil, json: .contains(["data": .equals("${test}")]))

        XCTAssertEqual(validation.json,
                       .contains(["data": .equals("${test}")]))

        let vars: [Key: Value] = ["test": "resolved"]
        let resolved = try validation.substitute(variables: vars)
        XCTAssertEqual(resolved.json,
                       .contains(["data": .equals("resolved")]))
    }

}
