//
//  Console.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 21/02/2019.
//

import Foundation
import Rainbow


protocol Console {
    func display(label: String, value: Any)
    func display(verbose message: String)
    func display(error: Error)
}


struct DefaultConsole: Console {
    func display(label: String, value: Any) {
        let msg = "\(label):".magenta.bold + " \(value)"
        print(msg, terminator: "\n\n")
    }

    func display(verbose message: String) {
        print(message.lightWhite.italic)
    }

    func display(error: Error) {
        print("❌  Error: \(error.legibleLocalizedDescription)")
    }
}
