//
//  Value.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public typealias Key = String


public enum Value: Equatable {
    case int(Int)
    case string(String)
    case double(Double)
    case dictionary([Key: Value])
    case array([Value])
}


extension Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode([Key: Value].self) {
            self = .dictionary(value)
            return
        }

        if let value = try? container.decode([Value].self) {
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let v):
            try container.encode(v)
        case .int(let v):
            try container.encode(v)
        case .double(let v):
            try container.encode(v)
        case .dictionary(let v):
            try container.encode(v)
        case .array(let v):
            try container.encode(v)
        }
    }
}


extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int(let v):
            return v.description
        case .string(let v):
            return v
        case .double(let v):
            return v.description
        case .dictionary(let v):
            return v.description
        case .array(let v):
            return v.description
        }
    }
}

