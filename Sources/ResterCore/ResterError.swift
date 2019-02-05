//
//  ResterError.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public enum ResterError: Error {
    case decodingError(String)
    case undefinedVariable(String)
    case invalidURL(String)
    case noSuchRequest(String)
    case fileNotFound(String)
    case internalError(String)

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
        case .internalError(let msg):
            return "internal error: \(msg)"
        }
    }
}


public func errorHandling(block: () throws -> ()) {
    do {
        try block()
    } catch let error as DecodingError {
        if
            case let .dataCorrupted(error) = error,
            let underlying = error.underlyingError {

            if let e = underlying as? ResterError {
                print("❌  \(e.localizedDescription)")
            } else {
                print("❌  Error: \(underlying.localizedDescription)")
            }
        } else {
            print("❌  Error: \(error.localizedDescription)")
        }
        exit(1)
    } catch let error as ResterError {
        // this special casing is required to get ResterError details
        print("❌  Error: \(error.localizedDescription)")
        exit(1)
    } catch {
        print("❌  Error: \(error.localizedDescription)")
        exit(1)
    }
}
