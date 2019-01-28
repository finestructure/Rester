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
        XCTAssertEqual(t.validation.json?["int"], .equals(.int(42)))
        XCTAssertEqual(t.validation.json?["string"], .equals(.string("foo")))
        XCTAssertEqual(t.validation.json?["regex"], .regex(".*".r!))
        XCTAssertEqual(t.validation.json?["object"], .contains(["foo": .equals("bar")]))
    }

    func test_validate() throws {
        XCTAssertEqual(try Matcher(200).validate(200), .valid)
        XCTAssertEqual(try Matcher(200).validate(404), .invalid("(404) is not equal to (200)"))
        XCTAssertEqual(try Matcher("foo").validate("foo"), .valid)
        XCTAssertEqual(try Matcher(200).validate("foo"), .invalid("(\"foo\") is not equal to (200)"))
        XCTAssertEqual(try Matcher(200).validate("200"), .invalid("(\"200\") is not equal to (200)"))

        XCTAssertEqual(try Matcher(".regex(\\d\\d)").validate("foo42"), .valid)
        XCTAssertEqual(try Matcher(".regex(\\d\\d)").validate("foo"), .invalid("(foo) does not match (\\d\\d)"))

        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar"]), .valid)
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["nope": "-"]), .invalid("key \'foo\' not found in \'[\"nope\": \"-\"]\'"))
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "-"]), .invalid("key \'foo\' validation error: (\"-\") is not equal to (\"bar\")"))
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar", "extra": "value"]), .valid)
        XCTAssertEqual(try Matcher(["foo": "bar"]).validate(["foo": "bar", "mixed_type": 1]), .valid)
    }
}
