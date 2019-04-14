//
//  Response.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


public struct Response: Equatable {
    public let elapsed: TimeInterval
    let data: Data
    let response: HTTPURLResponse
    let json: Value?
    let variables: [Key: Value]

    init(elapsed: TimeInterval, data: Data, response: HTTPURLResponse, variables: [Key: Value]) throws {
        self.elapsed = elapsed
        self.data = data
        self.response = response
        self.json = data.json
        self.variables = try self.json.map { try variables.substitute(variables: ["json": $0]) } ?? [:]
    }

    var status: Int {
        return response.statusCode
    }

    var headers: [Key: Value] {
        let headers = response.allHeaderFields
        let res: [(String, Value)] = headers.compactMap {
            guard
                let key = $0.key as? String,
                let value = $0.value as? String
                else { return nil }
            return (key, Value.string(value))
        }
        return Dictionary(uniqueKeysWithValues: res)
    }

}


extension Response: CustomStringConvertible {
    public var description: String {
        return """
        Status:   \(response.statusCode)
        Headers:  \(response.allHeaderFields)
        Data:     \(data.count) bytes
        """
    }
}
