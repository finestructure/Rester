//
//  ValidationResult.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


public enum ValidationResult {
    case valid
    case invalid(_ message: String)
}
