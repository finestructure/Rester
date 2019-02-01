//
//  Body.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 26/01/2019.
//

import Foundation


public struct Body: Codable {
    let json: [Key: Value]?
    let form: [Key: Value]?
}


extension Body: Substitutable {
    func substitute(variables: [Key : Value]) throws -> Body {
        func sub(_ input: [Key: Value]?) throws -> [Key: Value]? {
            // TODO: consider transforming keys (but be aware that uniqueKeysWithValues
            // below will then trap at runtime if substituted keys are not unique)
            guard let substituted = try input?.map({ ($0.key, try $0.value.substitute(variables: variables)) })
                else { return nil }
            return Dictionary(uniqueKeysWithValues: substituted)
        }

        return Body(json: try sub(json), form: try sub(form))
    }
}


