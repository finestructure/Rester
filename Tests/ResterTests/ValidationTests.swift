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



public typealias Key = String


public struct _Validation: Decodable {
    let status: _Matcher?
    let json: [Key: _Matcher]?

    private struct Detail: Decodable {
        let status: Value?
        let json: [Key: Value]?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let details = try container.decode(Detail.self)

        status = try details.status.map { try _Matcher(value: $0) }
        json = try details.json?.mapValues { try _Matcher(value: $0) }
    }
}


enum _Matcher {
    case equals(Value)
    case regex(Regex)
    case contains([Key: _Matcher])

    init(value: Value) throws {
        switch value {
        case .int, .double, .array:
            self = .equals(value)
        case .string(let string):
            self = try _Matcher.parse(string: string)
        case .dictionary(let dict):
            let matcherDict = try dict.mapValues { try _Matcher(value: $0) }
            self = .contains(matcherDict)
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

    func validate(_ value: Value) -> ValidationResult {
        switch (self, value) {
        case let (.equals(expected), value):
            return expected == value
                ? .valid
                : .invalid("(\(value)) is not equal to (\(expected))")
        case let (.regex(expected), .string(value)):
            return expected ~= value
                ? .valid
                : .invalid("(\(value)) does not match (\(expected.pattern))")
        case let (.contains(expected), .dictionary(dict)):
            for (key, exp) in expected {
                guard let val = dict[key] else { return .invalid("Key '\(key)' not found in '\(dict)'") }
                if case let .invalid(error) = exp.validate(val) {
                    return .invalid("Key '\(key)' validation error: \(error)")
                }
            }
            return .valid
        default:
            return .invalid("to be implemented")
        }
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


// conveniece initialisers
extension _Matcher {
    init(_ int: Int) throws {
        try self.init(value: Value.int(int))
    }
    init(_ double: Double) throws {
        try self.init(value: Value.double(double))
    }
    init(_ string: String) throws {
        try self.init(value: Value.string(string))
    }
    init(_ dict: [Key: Value]) throws {
        try self.init(value: Value.dictionary(dict))
    }
}

extension Value: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Value: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        let dict = Dictionary(uniqueKeysWithValues: elements)
        self = .dictionary(dict)
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

        let dict = Value.dictionary(["foo" : .string("bar")])
        XCTAssertEqual(try _Matcher(value: dict), .contains(["foo" : .equals("bar")]))
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
        XCTAssertEqual(try _Matcher(200).validate(200), .valid)
        XCTAssertEqual(try _Matcher(200).validate(404), .invalid("(404) is not equal to (200)"))
        XCTAssertEqual(try _Matcher("foo").validate("foo"), .valid)
        XCTAssertEqual(try _Matcher(200).validate("foo"), .invalid("(\"foo\") is not equal to (200)"))
        XCTAssertEqual(try _Matcher(200).validate("200"), .invalid("(\"200\") is not equal to (200)"))

        XCTAssertEqual(try _Matcher(".regex(\\d\\d)").validate("foo42"), .valid)
        XCTAssertEqual(try _Matcher(".regex(\\d\\d)").validate("foo"), .invalid("(foo) does not match (\\d\\d)"))

        XCTAssertEqual(try _Matcher(["foo": "bar"]).validate(["foo": "bar"]), .valid)
        XCTAssertEqual(try _Matcher(["foo": "bar"]).validate(["nope": "-"]), .invalid("Key \'foo\' not found in \'[\"nope\": \"-\"]\'"))
        XCTAssertEqual(try _Matcher(["foo": "bar"]).validate(["foo": "-"]), .invalid("Key \'foo\' validation error: (\"-\") is not equal to (\"bar\")"))
        XCTAssertEqual(try _Matcher(["foo": "bar"]).validate(["foo": "bar", "extra": "value"]), .valid)
        XCTAssertEqual(try _Matcher(["foo": "bar"]).validate(["foo": "bar", "mixed_type": 1]), .valid)
    }
}
