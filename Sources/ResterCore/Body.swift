//
//  Body.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 26/01/2019.
//

import Foundation


public enum Body {
    case json([Key: Value])
    case form([Key: Value])
    case multipart([Key: Value])
    case raw(String)
}


extension Body: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode([Key: Value].self, forKey: .json) {
            self = .json(value)
            return
        }
        if let value = try? container.decode([Key: Value].self, forKey: .form) {
            self = .form(value)
            return
        }
        if let value = try? container.decode([Key: Value].self, forKey: .multipart) {
            self = .multipart(value)
            return
        }
        if let value = try? container.decode(String.self, forKey: .raw) {
            self = .raw(value)
            return
        }
        throw ResterError.decodingError(
            "body must include one of \(CodingKeys.allCases.map { $0.stringValue }.joined(separator: ", "))"
        )
    }

    enum CodingKeys: CodingKey, CaseIterable {
        case json
        case form
        case multipart
        case raw
    }
}


extension Body: Substitutable {
    func substitute(variables: [Key : Value]) throws -> Body {
        switch self {
        case let .json(dict):
            return .json(try dict.substitute(variables: variables))
        case let .form(dict):
            return .form(try dict.substitute(variables: variables))
        case let .multipart(dict):
            return .multipart(try dict.substitute(variables: variables))
        case .raw:
            return self
        }
    }
}
