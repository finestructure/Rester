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
        return Body(json: try json?.substitute(variables: variables), form: try form?.substitute(variables: variables))
    }
}
