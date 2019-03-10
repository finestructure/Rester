//
//  Validation.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public struct Validation: Decodable {
    let status: Matcher?
    let headers: Matcher?
    let json: Matcher?

    private struct Detail: Decodable {
        let status: Value?
        let headers: Value?
        let json: Value?

        enum CodingKeys: CodingKey, CaseIterable {
            // we define these even though they're strictly not necessary for decoding
            // for the purpose of checking for extra keys (to catch typos)
            case status
            case headers
            case json
        }
    }

    public init(from decoder: Decoder) throws {
        do {
            // check no unexpected keys are present so we don't silently skip
            // validations that have mistyped keys
            let container = try decoder.container(keyedBy: OrderedCodingKeys.self)
            let expectedKeys = Detail.CodingKeys.allCases.map { $0.stringValue }
            for key in container.allKeys {
                if !expectedKeys.contains(key.stringValue) {
                    throw ResterError.unexpectedKeyFound(key.stringValue)
                }
            }
        }

        let container = try decoder.singleValueContainer()
        let details = try container.decode(Detail.self)

        status = try details.status.map { try Matcher(value: $0) }
        headers = try details.headers.map { try Matcher(value: $0) }
        json = try details.json.map { try Matcher(value: $0) }
    }

    init(status: Matcher?, headers: Matcher?, json: Matcher?) {
        self.status = status
        self.headers = headers
        self.json = json
    }
}


extension Validation: Substitutable {
    func substitute(variables: [Key : Value]) throws -> Validation {
        let _status = try status?.substitute(variables: variables)
        let _headers = try headers?.substitute(variables: variables)
        let _json = try json?.substitute(variables: variables)
        return Validation(status: _status, headers: _headers, json: _json)
    }
}
