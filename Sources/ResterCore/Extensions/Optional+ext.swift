//
//  Optional+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 05/04/2019.
//

import Commander


// Credit: https://github.com/kylef/Commander/issues/69#issuecomment-451629244

extension Optional: CustomStringConvertible where Wrapped: ArgumentConvertible {
    public var description: String {
        if let val = self {
            return "Some(\(val))"
        }
        return "None"
    }
}


extension Optional: ArgumentConvertible where Wrapped: ArgumentConvertible {
    public init(parser: ArgumentParser) throws {
        if let parser = parser.shift().map({ ArgumentParser(arguments: [$0]) }) {
            self = try Wrapped(parser: parser)
        } else {
            self = .none
        }
    }
}

