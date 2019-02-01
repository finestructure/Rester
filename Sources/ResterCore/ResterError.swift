//
//  ResterError.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import Path


public enum ResterError: Error {
    case decodingError(String)
    case undefinedVariable(String)
    case invalidURL(String)
    case noSuchRequest(String)
    case fileNotFound(Path)

    public var localizedDescription: String {
        switch self {
        case .decodingError(let msg):
            return "decoding error: \(msg)"
        case .undefinedVariable(let variable):
            return "undefined variable: \(variable)"
        case .invalidURL(let url):
            return "invalid url: \(url)"
        case .noSuchRequest(let req):
            return "no such request: \(req)"
        case .fileNotFound(let file):
            return "file not found: \(file)"
        }
    }
}
