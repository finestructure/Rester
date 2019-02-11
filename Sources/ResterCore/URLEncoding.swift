//
//  URLEncoding.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


protocol URLEncoding {
    var urlEncoded: String? { get }
}


extension String: URLEncoding {
    var urlEncoded: String? {
        let allowed = CharacterSet.urlHostAllowed.subtracting(CharacterSet(charactersIn: "+"))
        return addingPercentEncoding(withAllowedCharacters: allowed)
    }
}


struct Parameter {
    let key: Key
    let value: Value

    init?(key: Key?, value: Value?) {
        if let key = key, let value = value {
            self.key = key
            self.value = value
        } else {
            return nil
        }
    }
}


extension Parameter: URLEncoding {
    var urlEncoded: String? {
        guard let key = key.urlEncoded, let value = value.urlEncoded else {
            return nil
        }
        return "\(key)=\(value)"
    }
}


extension Dictionary where Key == ResterCore.Key, Value == ResterCore.Value {
    var formUrlEncoded: String {
        return compactMap { Parameter(key: $0.key.urlEncoded, value: $0.value)}
            .compactMap { $0.urlEncoded }
            .joined(separator: "&")
    }
}
