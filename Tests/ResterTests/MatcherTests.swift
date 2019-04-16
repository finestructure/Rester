//
//  MatcherTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 16/04/2019.
//

@testable import ResterCore
import XCTest
import Yams


class MatcherTests: XCTestCase {

    func test_init_with_value() throws {
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

    func test_decodable() throws {
        let s = """
           eq: 5
           regex: .regex(.*)
           contains:
             foo: bar
        """
        struct Test: Decodable {
            let eq: Matcher
            let regex: Matcher
            let contains: Matcher
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.eq, .equals(5))
        XCTAssertEqual(t.regex, .regex(".*".r!))
        XCTAssertEqual(t.contains, .contains(["foo": .equals("bar")]))
    }

    func test_validate() throws {
        XCTAssertEqual(try Matcher(200).validate(200), .valid)
        XCTAssertEqual(try Matcher(200).validate(404), .invalid("(404) is not equal to (200)"))
        XCTAssertEqual(try Matcher("foo").validate("foo"), .valid)
        XCTAssertEqual(try Matcher(200).validate("foo"), .invalid("(\"foo\") is not equal to (200)"))
        XCTAssertEqual(try Matcher(200).validate("200"), .invalid("(\"200\") is not equal to (200)"))

        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar"]), .valid)
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["nope": "-"]), .invalid("key \'foo\' not found in \'[\"nope\": \"-\"]\'"))
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "-"]), .invalid("key \'foo\' validation error: (\"-\") is not equal to (\"bar\")"))
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar", "extra": "value"]), .valid)
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar", "mixed_type": 1]), .valid)
    }

    func test_validate_regex() throws {
        XCTAssertEqual(try Matcher(".regex(\\d\\d)").validate("foo42"), .valid)
        XCTAssertEqual(try Matcher(".regex(\\d\\d)").validate("foo"), .invalid("(\"foo\") does not match (\\d\\d)"))
        XCTAssertEqual(try Matcher(".regex(\\d+)").validate("15698703"), .valid)
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
                           .invalid("index \'0\' validation error: key \'foo\' not found in \'[\"nope\": \"-\"]\'"))
        }
    }

    func test_substitute() throws {
        let vars: [Key: Value] = ["test": "resolved"]
        XCTAssertEqual(try Matcher(value: "${test}").substitute(variables: vars),
                       .equals("resolved"))
        XCTAssertEqual(try Matcher(value: ["data": "${test}"]).substitute(variables: vars),
                       .contains(["data": .equals("resolved")]))
    }

    func test_doesNotEqual() throws {
        XCTAssertEqual(Matcher.doesNotEqual(42).validate(0), .valid)
        XCTAssertEqual(Matcher.doesNotEqual(42).validate(42), .invalid("(42) does equal (42)"))
    }

    func test_decodable_doesNotEqual() throws {
        let s = """
           value: .doesNotEqual(5)
           array: .doesNotEqual([])
        """
        struct Test: Decodable {
            let value: Matcher
            let array: Matcher
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.value, .doesNotEqual(5))
        XCTAssertEqual(t.array, .doesNotEqual(.array([])))
    }

}
