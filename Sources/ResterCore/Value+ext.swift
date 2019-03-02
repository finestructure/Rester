//
//  Value.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import ValueCodable


extension Value: URLEncoding {
    var urlEncoded: String? {
        switch self {
        case .bool(let v):
            return v.description
        case .int(let v):
            return String(v).urlEncoded
        case .string(let v):
            return v.urlEncoded
        case .double(let v):
            return String(v).urlEncoded
        case .dictionary(let v):
            return v.formUrlEncoded
        case .array(let v):
            return "[" + v.compactMap { $0.urlEncoded }.joined(separator: ",") + "]"
        case .null:
            return "null"
        }
    }
}


extension Value: Substitutable {
    func substitute(variables: [Key : Value]) throws -> Value {
        switch self {
        case .string(let string):
            return try .string(ResterCore.substitute(string: string, with: variables))
        default:
            return self
        }
    }
}


extension Dictionary: Substitutable where Key == ValueCodable.Key, Value == ValueCodable.Value {
    func substitute(variables: [Key : Value]) throws -> Dictionary<Key, Value> {
        // TODO: consider transforming keys (but be aware that uniqueKeysWithValues
        // below will then trap at runtime if substituted keys are not unique)
        let substituted = try self.map { ($0.key, try $0.value.substitute(variables: variables)) }
        return Dictionary(uniqueKeysWithValues: substituted)
    }
}
