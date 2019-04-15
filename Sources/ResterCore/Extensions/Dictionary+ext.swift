//
//  Dictionary+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 14/02/2019.
//

import Foundation


enum MergeStrategy {
    case firstWins
    case lastWins
}


extension Dictionary {
    func merging(_ other: [Key : Value], strategy: MergeStrategy) -> [Key : Value] {
        switch strategy {
        case .firstWins:
            return self.merging(other, uniquingKeysWith: {old, _ in old})
        case .lastWins:
            return self.merging(other, uniquingKeysWith: {_, new in new})
        }
    }
}


extension Dictionary: Substitutable where Key == ResterCore.Key, Value == ResterCore.Value {
    func substitute(variables: [Key : Value]) throws -> Dictionary<Key, Value> {
        // TODO: consider transforming keys (but be aware that uniqueKeysWithValues
        // below will then trap at runtime if substituted keys are not unique)
        let substituted = try self.map { ($0.key, try $0.value.substitute(variables: variables)) }
        return Dictionary(uniqueKeysWithValues: substituted)
    }
}


extension Dictionary where Key == ResterCore.Key, Value == ResterCore.Value {
    var formUrlEncoded: String {
        return compactMap { Parameter(key: $0.key.urlEncoded, value: $0.value) }
            .compactMap { $0.urlEncoded }
            .joined(separator: "&")
    }
}


extension Dictionary: MultipartEncoding where Key == ResterCore.Key, Value == ResterCore.Value {
    func multipartEncoded() throws -> Data {
        let lineBreak = "\n".data(using: .utf8)!
        let boundary = MultipartBoundary.data(using: .utf8)!
        let endMarker = "--".data(using: .utf8)!

        let payloads = try compactMap { Parameter(key: $0.key, value: $0.value) }
            .sorted { $0.key < $1.key }
            .map { try $0.multipartEncoded() }
        // NB: joined produces data that is missing random characters!
        // therefore we have to do our own joining below
        //  .joined(separator: lineBreak)

        guard payloads.count > 0 else {
            throw ResterError.internalError("multipart encoding requires at least one parameter")
        }

        let tail = payloads[1...].reduce(Data()) { $0 + lineBreak + $1 }
        return payloads[0] + tail + lineBreak + boundary + endMarker
    }
}


extension Dictionary where Key == ResterCore.Key, Value == ResterCore.Value {
    /// Append variables to values of the same key if they are "append values",
    /// i.e. if they are defined as `.append(value)`.
    ///
    /// - Parameter variables: Dictionary to search for append values
    /// - Returns: Dictionary with appended values
    public func append(variables: [Key: Value]) -> [Key: Value] {
        return Dictionary(uniqueKeysWithValues:
            map { (item) -> (Key, Value) in
                if let value = variables[item.key],
                    let appendValue = value.appendValue,
                    case let .array(arr) = item.value {
                    return (item.key, .array(arr + [.string(appendValue)]))
                }
                return (item.key, item.value)
            }
        )
    }

    public func append(values: Value?) -> [Key: Value] {
        guard case let .dictionary(dict)? = values else { return self }
        return append(variables: dict)
    }
}
