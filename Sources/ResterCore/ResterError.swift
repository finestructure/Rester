//
//  ResterError.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation

enum ResterError: Error {
    case decodingError(String)
    case undefinedVariable(String)
    case invalidURL(String)
    case noSuchRequest(String)
}
