//
//  ValueTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 27/01/2019.
//

import XCTest
//@testable import ResterCore

import Yams


enum _Value: Equatable {
    case int(Int)
    case string(String)
    case double(Double)
}

extension _Value: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // string decoding must be possible
        let string = try container.decode(String.self)

        // strings with a colon get parsed as Numeric (with value 0) for some reason
        // therefore just accept them as string and return
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
            """
        struct Test: Decodable {
            let int: _Value
            let string: _Value
            let stringColon: _Value
            let double: _Value
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.int, .int(42))
        XCTAssertEqual(t.string, .string("some string value"))
        XCTAssertEqual(t.stringColon, .string("foo: bar"))
        XCTAssertEqual(t.double, .double(3.14))
    }

}
