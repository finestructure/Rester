//
//  Substitutable.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation
import Regex


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
