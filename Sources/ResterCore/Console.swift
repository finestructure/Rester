//
//  Console.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 21/02/2019.
//

import Foundation
import Rainbow


public protocol Console {
    mutating func display(_ message: String, terminator: String)
    mutating func display(key: String, value: Any)
    mutating func display(verbose message: String)
    mutating func display(_ error: Error)
}


extension Console {
    mutating func display(_ message: String) {
        display(message, terminator: "\n")
    }

    mutating func display(variables: [Key: Value]) {
        guard variables.count > 0 else { return }
        display(verbose: "Defined variables:")
        for v in variables.keys {
            display(verbose: "  - \(v)")
        }
        display(verbose: "")
    }

    mutating func display(summary total: Int, failed: Int) {
        let testLabel = (total == 1) ? "test" : "tests"
        let failure = failed == 0 ? "0".green.bold : String(failed).red.bold
        let failureLabel = (failed == 1) ? "failure" : "failures"
        display("Executed \(String(total).bold) \(testLabel), with \(failure) \(failureLabel)")
    }

    mutating func display(_ stats: [Request.Name: Stats]?) {
        guard let stats = stats else { return }
        for (name, stats) in stats.sorted(by: { $0.key < $1.key }) {
            print(name.blue)
            print(stats)
            print()
        }
    }
}


struct DefaultConsole: Console {
    mutating func display(_ message: String, terminator: String) {
        print(message, terminator: terminator)
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
