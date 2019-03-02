//
//  Substitutable.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation
import Regex
import ValueCodable


protocol Substitutable {
    func substitute(variables: [Key: Value]) throws -> Self
}


func substitute(string: String, with variables: [Key: Value]) throws -> String {
    let regex = try Regex(pattern: "\\$\\{(.*?)\\}", groupNames: "variable")
    let res = regex.replaceAll(in: string) { match in
        guard let varName = match.group(named: "variable") else { return nil }
        // use Value.subscript for key path lookups: value["foo.0.baz"]
        if let value = Value.dictionary(variables)[varName] {
            return value.string
        }
        if let value = Current.environment[varName] {
            return value
        }
        return nil
    }

    if res =~ regex {
        throw ResterError.undefinedVariable(res)
    }
    return res
}


extension Dictionary: Substitutable where Key == ValueCodable.Key, Value == ValueCodable.Value {
    func substitute(variables: [Key : Value]) throws -> Dictionary<Key, Value> {
        // TODO: consider transforming keys (but be aware that uniqueKeysWithValues
        // below will then trap at runtime if substituted keys are not unique)
        let substituted = try self.map { ($0.key, try $0.value.substitute(variables: variables)) }
        return Dictionary(uniqueKeysWithValues: substituted)
    }
}
