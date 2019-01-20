//
//  Matcher.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import Regex


public enum Matcher: Equatable {
    case int(Int)
    case string(String)
    case regex(String)
}

extension Matcher: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // string decoding must be possible
        let string = try container.decode(String.self)
        if
            let match = try? Regex(pattern: ".regex\\((.*?)\\)", groupNames: "regex").findFirst(in: string),
            let regex = match?.group(named: "regex") {
            self = .regex(regex)
            return
        }
        if let int = try? container.decode(Int.self) {
            self = .int(int)
            return
        }
        self = .string(string)
    }

    public func encode(to encoder: Encoder) throws {

    }
}
