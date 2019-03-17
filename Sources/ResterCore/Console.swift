//
//  Console.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 21/02/2019.
//

import Foundation
import Rainbow


public protocol Console {
    mutating func display(_ message: String)
    mutating func display(key: String, value: Any)
    mutating func display(verbose message: String)
    mutating func display(_ error: Error)
}


struct DefaultConsole: Console {
    mutating func display(_ message: String) {
        print(message)
    }

    mutating func display(key: String, value: Any) {
        let msg = "\(key):".magenta.bold + " \(value)"
        print(msg, terminator: "\n\n")
    }

    mutating func display(verbose message: String) {
        print(message.lightWhite.italic)
    }

    mutating func display(_ error: Error) {
        if
            let decodingError = error as? DecodingError,
            case let .dataCorrupted(err) = decodingError,
            let underlying = err.underlyingError as? ResterError {
            print("❌  Restfile syntax error: \(underlying.legibleLocalizedDescription)")
        } else {
            print("❌  Error: \(error.legibleLocalizedDescription)")
        }
    }
}
