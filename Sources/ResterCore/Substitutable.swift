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
        if
            let varName = match.group(named: "variable"),
            let value = variables[varName]?.substitutionDescription {
            return value
        } else {
            return nil
        }
    }

    if res =~ regex {
        throw ResterError.undefinedVariable(res)
    }
    return res
}

