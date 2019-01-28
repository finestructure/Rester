//
//  Validation.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public struct Validation: Decodable {
    let status: Matcher?
    // TODO: Change this as follows?
    //   let json: Matcher?
    // where Matcher is .contains([Key: Matcher])
    let json: [Key: Matcher]?

    private struct Detail: Decodable {
        let status: Value?
        let json: [Key: Value]?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let details = try container.decode(Detail.self)

        status = try details.status.map { try Matcher(value: $0) }
        json = try details.json?.mapValues { try Matcher(value: $0) }
    }
}

