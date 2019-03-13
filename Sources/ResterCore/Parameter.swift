//
//  Parameter.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 13/03/2019.
//

import Foundation


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


extension Parameter: MultipartEncoding {
    var multipartEncoded: String? {
        return multipartEncode(key: key, value: value)
    }
}
