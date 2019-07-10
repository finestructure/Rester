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


enum Operators: String, CaseIterable {
    case base64

    private static let groupName = "operand"

    var regex: Regex {
        return try! Regex(pattern: #".\#(rawValue)\((.*?)\)"#, groupNames: Operators.groupName)
    }

    func apply(to string: String) -> String {
        return regex.replaceAll(in: string) { (match) -> String? in
            guard let operand = match.group(named: Operators.groupName) else { return nil }
            return transform(operand)
        }
    }

    var transform: (String) -> String {
        switch self {
        case .base64:
            return { $0.base64 }
        }
    }
}


func substitute(string: String, with variables: [Key: Value]) throws -> String {
    let regex = try Regex(pattern: "\\$\\{(.*?)\\}", groupNames: "variable")
    let variableSubstitutedString = regex.replaceAll(in: string) { match in
        guard let varName = match.group(named: "variable") else { return nil }
        // use Value.subscript for key path lookups: value["foo[0].baz"]
        if let value = Value.dictionary(variables)[varName] {
            return value.string
        }
        if let value = Current.environment[varName] {
            return value
        }
        return nil
    }

    // Check if unmatched variables remain
    if variableSubstitutedString =~ regex {
        throw ResterError.undefinedVariable(variableSubstitutedString)
    }

    // Find and apply operators
    let operatorAppliedString = Operators.allCases.reduce(variableSubstitutedString) { string, op -> String in
        op.apply(to: string)
    }

    return operatorAppliedString
}
