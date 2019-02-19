//
//  ValidationResult.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


public enum ValidationResult {
    case valid
    case invalid(_ message: String, value: Value?)
}


extension ValidationResult {
    // TODO: remove once enums support default values https://github.com/apple/swift/pull/21381
    init(invalid message: String, value: Value? = nil) {
        self = .invalid(message, value: value)
    }
}
