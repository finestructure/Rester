//
//  Multipart.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 13/03/2019.
//

import Foundation


let MultipartBoundary = "--__X_RESTER_BOUNDARY__"


protocol MultipartEncoding {
    var multipartEncoded: String? { get }
}


func multipartEncode(key: Key, value: Value) -> String {
    return """
        \(MultipartBoundary)
        Content-Disposition: form-data; name="\(key)"

        \(value.string)
        """
}
