//
//  Matcher.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import Regex


public enum Matcher {
    case int(Int)
    case string(String)
    case regex(Regex)
}


extension Matcher: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // string decoding must be possible
        let string = try container.decode(String.self)
        if
            let match = try? Regex(pattern: ".regex\\((.*?)\\)", groupNames: "regex").findFirst(in: string),
            let regexString = match?.group(named: "regex") {
            guard let regex = regexString.r else {
                throw ResterError.decodingError("invalid regex in '\(regexString)'")
            }
            self = .regex(regex)
            return
        }
        if let int = try? container.decode(Int.self) {
            self = .int(int)
            return
        }
        self = .string(string)
    }
}


extension Matcher: Equatable {
    public static func == (lhs: Matcher, rhs: Matcher) -> Bool {
        switch (lhs, rhs) {
        case let (.int(x), .int(y)):
            return x == y
        case let (.string(x), .string(y)):
            return x == y
        case let (.regex(x), .regex(y)):
            return x.pattern == y.pattern
        default:
            return false
        }
    }
}
