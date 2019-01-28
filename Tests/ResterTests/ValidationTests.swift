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



typealias Key = String

struct ValidationDetail: Decodable {
    let status: Value?
    let json: [Key: Value]?
}

public struct _Validation: Decodable {
    let status: Matcher?
    let json: [Key: Matcher]?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let details = try container.decode(ValidationDetail.self)

        status = nil
        json = nil
    }
}


enum _Matcher {
    case equals(Value)
    case regex(Regex)
    case contains([Key: Value])

    init(value: Value) throws {
        switch value {
        case .int, .double, .array:
            self = .equals(value)
        case .string(let string):
            self = try _Matcher.parse(string: string)
        case .dictionary(let dict):
            self = .contains(dict)
        default:
            throw ResterError.decodingError("Failed to initialise Matcher with value '\(value)'")
        }
    }

    static func parse(string: String) throws -> _Matcher {
        if  // .regex(...)
            let match = try? Regex(pattern: ".regex\\((.*?)\\)", groupNames: "regex").findFirst(in: string),
            let regexString = match?.group(named: "regex") {
            guard let regex = regexString.r else {
                throw ResterError.decodingError("invalid .regex in '\(regexString)'")
            }
            return .regex(regex)
        }

        return .equals(.string(string))
    }
}


extension _Matcher: Equatable {
    public static func == (lhs: _Matcher, rhs: _Matcher) -> Bool {
        switch (lhs, rhs) {
        case let (.equals(x), .equals(y)):
            return x == y
        case let (.regex(x), .regex(y)):
            return x.pattern == y.pattern
        case let (.contains(x), .contains(y)):
            return x == y
        default:
            return false
        }
    }
}


class ValidationTests: XCTestCase {

    func test_convertMatcher() throws {
        let int = Value.int(200)
        let double = Value.double(3.14)
        let string = Value.string("a")
        let array = Value.array([int, string])
        XCTAssertEqual(try _Matcher(value: int), .equals(int))
        XCTAssertEqual(try _Matcher(value: double), .equals(double))
        XCTAssertEqual(try _Matcher(value: string), .equals(string))
        XCTAssertEqual(try _Matcher(value: array), .equals(array))

        let regex = Value.string(".regex(.*)")
        XCTAssertEqual(try _Matcher(value: regex), .regex(".*".r!))
        // TODO: implement .in operator
        //        let `in` = Value.string(".in(200, 201)")
        //        XCTAssertEqual(try _Matcher(value: `in`), .in([.int(200), .int(201)]))

        let dict = Value.dictionary(["foo" : .string("bar")])
        XCTAssertEqual(try _Matcher(value: dict), .contains(["foo" : .string("bar")]))
    }

    func test_parse_Validation() throws {
        struct Test: Decodable {
            let validation: _Validation
        }
        let s = """
        validation:
          status: 200
          json:
            int: 42
            string: foo
            regex: .regex(\\d+\\.\\d+\\.\\d+|\\S{40})
            object:
              foo: bar
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.status, .int(200))
        XCTAssertEqual(t.validation.json?["int"], .int(42))
        XCTAssertEqual(t.validation.json?["string"], .string("foo"))
//        XCTAssertEqual(t.validation.json!["regex"], .regex("\\d+\\.\\d+\\.\\d+|\\S{40}".r!))
//        XCTAssertEqual(t.validation.json!["object"], .object(["foo": .string("bar")]))
        XCTAssertEqual(t.validation.json?["regex"], .string(".regex(\\d+\\.\\d+\\.\\d+|\\S{40})"))
//        XCTAssertEqual(t.validation.json!["object"], .dictionary(["foo": .string("bar")]))
    }

}
