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

    var json: Value? {
        if let data = try? JSONDecoder().decode([Key: Value].self, from: data) {
            return .dictionary(data)
        } else if let data = try? JSONDecoder().decode([Value].self, from: data) {
            return .array(data)
        } else {
            return nil
        }
    }

}
