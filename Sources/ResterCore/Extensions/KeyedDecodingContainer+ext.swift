//
//  KeyedDecodingContainer+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 11/04/2019.
//

import Foundation


extension KeyedDecodingContainer {
    func decodeRequests(for key: KeyedDecodingContainer.Key) throws -> [Request] {
        if contains(key) {
            do {
                let req = try decode(OrderedDict<Request.Name, Request.Details>.self, forKey: key)
                return req.items.compactMap { $0.first }.map { Request(name: $0.key, details: $0.value) }
            } catch let DecodingError.keyNotFound(key, _) {
                throw ResterError.keyNotFound(key.stringValue)
            }
        } else {
            return []
        }
    }
}
