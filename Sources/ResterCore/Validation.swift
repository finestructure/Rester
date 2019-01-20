//
//  Validation.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public struct Validation: Decodable {
    let status: Int?
    let json: [Key: Matcher]?
}
