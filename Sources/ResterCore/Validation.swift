//
//  Validation.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public struct Validation: Decodable {
    let status: Matcher?
    let json: Matcher?

    private struct Detail: Decodable {
        let status: Value?
        let json: Value?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let details = try container.decode(Detail.self)

        status = try details.status.map { try Matcher(value: $0) }
        json = try details.json.map { try Matcher(value: $0) }
    }
}

