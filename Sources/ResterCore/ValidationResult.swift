//
//  ValidationResult.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


public enum ValidationResult {
    case valid
    // TODO: make generic instead of using Response
    case invalid(_ message: String, response: Response?)

    init(invalid message: String, response: Response? = nil) {
        self = .invalid(message, response: response)
    }
}
