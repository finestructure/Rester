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

    enum CodingKeys: CodingKey, CaseIterable {
        // we define these even though they're strictly not necessary for decoding
        // for the purpose of checking for extra keys (to catch typos)
        case status
        case headers
        case json
    }

    public init(from decoder: Decoder) throws {
        do {
            // check no unexpected keys are present so we don't silently skip
            // validations that have mistyped keys
            let container = try decoder.container(keyedBy: StringCodingKeys.self)

            let expectedKeys = CodingKeys.allCases.map { $0.stringValue }
            for key in container.allKeys {
                if !expectedKeys.contains(key.stringValue) {
                    throw ResterError.unexpectedKeyFound(key.stringValue)
                }
            }
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        status = try? container.decode(Matcher.self, forKey: .status)
        headers = try? container.decode(Matcher.self, forKey: .headers)
        json = try? container.decode(Matcher.self, forKey: .json)
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
