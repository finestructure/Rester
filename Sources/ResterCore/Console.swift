//
//  Console.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 21/02/2019.
//

import Foundation
import Rainbow


public protocol Console {
    mutating func display(label: String, value: Any)
    mutating func display(verbose message: String)
    mutating func display(error: Error)
}


struct DefaultConsole: Console {
    mutating func display(label: String, value: Any) {
        let msg = "\(label):".magenta.bold + " \(value)"
        print(msg, terminator: "\n\n")
    }

    mutating func display(verbose message: String) {
        print(message.lightWhite.italic)
    }

    mutating func display(error: Error) {
        print("❌  Error: \(error.legibleLocalizedDescription)")
    }
}
