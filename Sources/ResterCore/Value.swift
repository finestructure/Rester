//
//  Value.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public enum Value: Equatable {
    case int(Int)
    case string(String)
}


extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int(let v):
            return String(v)
        case .string(let v):
            return v
        }
    }
}


extension Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // string decoding must be possible
        let stringValue = try container.decode(String.self)

        // strings with a colon get parsed as Int (with value 0) for some reason
        if !stringValue.contains(":"), let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }

        // default to string
        self = .string(stringValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
}
