//
//  ValueTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 27/01/2019.
//

import XCTest
//@testable import ResterCore

import Yams

typealias Key = String

enum _Value: Equatable {
    case int(Int)
    case string(String)
    case double(Double)
    case dictionary([Key: _Value])
    case array([_Value])
}

extension _Value: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode([Key: _Value].self) {
            self = .dictionary(value)
            return
        }

        if let value = try? container.decode([_Value].self) {
            self = .array(value)
            return
        }

        // string decoding must be possible at this point
        let string = try container.decode(String.self)

        // strings with a colon get parsed as Numeric (with value 0) *)
        // therefore just accept them as string and return
        // *) probably due to dictionary syntax
        if string.contains(":") {
            self = .string(string)
            return
        }

        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }

        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }

        // default to string
        self = .string(string)
    }
}


class ValueTests: XCTestCase {

    func test_basic_types() throws {
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
            let int: _Value
            let string: _Value
            let stringColon: _Value
            let double: _Value
            let dict: _Value
            let array: _Value
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.int, .int(42))
        XCTAssertEqual(t.string, .string("some string value"))
        XCTAssertEqual(t.stringColon, .string("foo: bar"))
        XCTAssertEqual(t.double, .double(3.14))
        XCTAssertEqual(t.dict, .dictionary(["a": .int(1), "b": .string("two")]))
        XCTAssertEqual(t.array, _Value.array([
            .int(1),
            .string("two"),
            .dictionary(["foo": .string("bar")])
            ]))
    }

}
