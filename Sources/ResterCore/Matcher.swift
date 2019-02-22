//
//  Matcher.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import Regex


enum Matcher {
    case equals(Value)
    case regex(Regex)
    case contains([Key: Matcher])
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
                : .init(invalid: "(\(value)) is not equal to (\(expected))")
        case let (.regex(expected), _):
            return expected ~= value.string
                ? .valid
                : .init(invalid: "(\(value)) does not match (\(expected.pattern))")
        case let (.contains(expected), .dictionary(dict)):
            for (key, exp) in expected {
                guard let val = dict[key] else { return .init(invalid: "key '\(key)' not found in '\(dict)'") }
                if case let .invalid(msg, resp) = exp.validate(val) {
                    return .invalid("key '\(key)' validation error: \(msg)", value: resp)
                }
            }
            return .valid
        case let (.contains(expected), .array):
            for (key, exp) in expected {
                guard let index = Int(key) else {
                    return .init(invalid: "key '\(key)' not convertible into index")
                }
                if
                    let element = value[index],
                    case let .invalid(msg, resp) = exp.validate(element) {
                    return .invalid("index '\(index)' validation error: \(msg)", value: resp)
                }
            }
            return .valid
        default:
            return .init(invalid: "failed to validate value '\(value)' with '\(self)'")
        }
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
