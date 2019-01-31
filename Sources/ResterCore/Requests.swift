//
//  Requests.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 21/01/2019.
//

import Foundation


public struct Requests {
    let items: [[Request.Name: Request.Details]]
}


extension Requests: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderedCodingKeys.self)
        self.items = try container.decodeOrdered(Request.Details.self)
    }
}


struct OrderedCodingKeys: CodingKey {
    var intValue: Int?
    var stringValue: String

    init?(intValue: Int) {
        return nil
    }

    init?(stringValue: String){
        self.stringValue = stringValue
    }
}


extension KeyedDecodingContainer where Key == OrderedCodingKeys {
    func decodeOrdered<T: Decodable>(_ type: T.Type) throws -> [[String: T]] {
        var data = [[String: T]]()

        for key in allKeys {
            let value = try decode(T.self, forKey: key)
            data.append([key.stringValue: value])
        }

        return data
    }
}


