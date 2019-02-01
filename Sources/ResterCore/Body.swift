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
