//
//  Multipart.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 13/03/2019.
//

import Foundation


let MultipartBoundary = "--__X_RESTER_BOUNDARY__"


protocol MultipartEncoding {
    func multipartEncoded() throws -> Data
}


func multipartEncode(key: Key, value: Value) throws -> Data {
    guard let data = """
        \(MultipartBoundary)
        Content-Disposition: form-data; name="\(key)"

        \(value.string)
        """.data(using: .utf8) else {
            throw ResterError.internalError("failed to encode multipart for key \(key)")
    }
    return data
}
