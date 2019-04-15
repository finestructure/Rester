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

    init(elapsed: TimeInterval, data: Data, response: URLResponse, variables: [Key: Value]) throws {
        self.elapsed = elapsed
        self.data = data
        guard let resp = response as? HTTPURLResponse else {
            throw ResterError.internalError("Failed to convert \(response) to HTTPURLResponse")
        }
        self.response = resp
        self.json = data.json
        self.variables = try resolve(variables: variables, json: json)
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


func resolve(variables: [Key: Value], json: Value?) throws -> [Key: Value] {
    // request r1:
    // variables:
    //    foo: json.method
    // -> variables = [foo: GET]
    guard let json = json else { return variables }
    let res: [Key: Value] = variables.mapValues { value in
        switch value {
        case .string(let s):
            if s.starts(with: "json.") || s.starts(with: "json[") {
                let dict: Value = ["json": json]
                if let v = dict[s] {
                    return v
                }
            }
        default:
            break
        }
        return value
    }
    guard case let .dictionary(dict) = json else {
        throw ResterError.internalError("Cannot resolve variables unless response is a JSON object")
    }
    return res.merging(dict, strategy: .lastWins)
}
