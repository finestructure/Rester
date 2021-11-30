//
//  ValidationResult.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


public typealias Reason = String


public enum ValidationResult: Equatable {
    case valid
    case invalid(Reason)
}
