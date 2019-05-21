//
//  Matcher.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import Regex
import Yams


enum Matcher {
    case equals(Value)
    case doesNotEqual(Value)
    case regex(Regex)
    case contains([Key: Matcher])
}


func findFirst(operator: String, in string: String) -> String? {
    guard
        let match = try? Regex(pattern: #"\.\#(`operator`)\((.*?)\)"#, groupNames: "value").findFirst(in: string),
        let value = match?.group(named: "value")
        else {
            return nil
    }
    return value
}


extension Matcher {
    init(value: Value) throws {
        switch value {
        case .bool, .int, .double, .array, .null:
            self = .equals(value)
        case .string(let string):
            self = try Matcher.parse(string: string)
        case .dictionary(let dict):
            let matcherDict = try dict.mapValues { try Matcher(value: $0) }
            self = .contains(matcherDict)
        }
    }

    static func parse(string: String) throws -> Matcher {
        if let value = findFirst(operator: "regex", in: string) {
            guard let regex = value.r else {
                throw ResterError.decodingError("invalid .regex in '\(value)'")
            }
            return .regex(regex)
        }
        if let value = findFirst(operator: "doesNotEqual", in: string) {
            // Use YAMLDecoder to parse Value from string representation
            let decoded = try YAMLDecoder().decode(Value.self, from: value)
            return .doesNotEqual(decoded)
        }

        return .equals(.string(string))
    }

    func validate(_ value: Value) -> ValidationResult {
        switch (self, value) {
        case let (.equals(expected), value):
            return expected == value
                ? .valid
                : .invalid("(\(value)) is not equal to (\(expected))")
        case let (.doesNotEqual(expected), value):
            return expected != value
                ? .valid
                : .invalid("(\(value)) does equal (\(expected))")
        case let (.regex(expected), _):
            return expected ~= value.string
                ? .valid
                : .invalid("(\(value)) does not match (\(expected.pattern))")
        case let (.contains(expected), .dictionary(dict)):
            for (key, exp) in expected {
                guard let val = dict[key] else { return .invalid("key '\(key)' not found in '\(dict)'") }
                if case let .invalid(msg) = exp.validate(val) {
                    return .invalid("key '\(key)' validation error: \(msg)")
                }
            }
            return .valid
        case let (.contains(expected), .array):
            for (key, exp) in expected {
                guard let index = Int(key) else {
                    return .invalid("key '\(key)' not convertible into index")
                }
                guard let element = value[index] else {
                    return .invalid("index \(index) out of bounds")
                }
                if case let .invalid(msg) = exp.validate(element) {
                    return .invalid("index '\(index)' validation error: \(msg)")
                }
            }
            return .valid
        default:
            return .invalid("failed to validate value '\(value)' with '\(self)'")
        }
    }
}


extension Matcher: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Value.self)
        self = try Matcher(value: value)
    }
}


extension Matcher: Equatable {
    public static func == (lhs: Matcher, rhs: Matcher) -> Bool {
        switch (lhs, rhs) {
        case let (.equals(x), .equals(y)):
            return x == y
        case let (.regex(x), .regex(y)):
            return x.pattern == y.pattern
        case let (.contains(x), .contains(y)):
            return x == y
        case let (.doesNotEqual(x), .doesNotEqual(y)):
            return x == y
        default:
            return false
        }
    }
}


// conveniece initialisers
extension Matcher {
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


extension Matcher: Substitutable {
    func substitute(variables: [Key : Value]) throws -> Matcher {
        switch self {
        case let .equals(value):
            return try .equals(value.substitute(variables: variables))
        case let .contains(value):
            let resolved = try value.mapValues { try $0.substitute(variables: variables) }
            return .contains(resolved)
        default:
            return self
        }
    }
}
