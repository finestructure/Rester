//
//  Parameter.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 13/03/2019.
//

import Foundation
import Path
import Regex


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
    func multipartEncoded() throws -> Data {
        if key == "file" {
            let file = try parseFile(value: value)
            return try multipartEncode(file: file)
        } else {
            return try multipartEncode(key: key, value: value)
        }
    }
}


func parseFile(value: Value) throws -> Path {
    // FIXME: deal with () in path names
    let regex = try Regex(pattern: ".file\\((.*?)\\)", groupNames: "file")
    guard
        let match = regex.findFirst(in: value.string),
        let file = match.group(named: "file")else {
        // TODO: provide new error type with more detail
        throw ResterError.internalError("expected to find .file(...) attribute")
    }
    if let path = Path(file) {
        // absolute path
        return path
    } else {
        return Current.workDir/file
    }
}


func multipartEncode(file: Path) throws -> Data {
    let data = try Data(contentsOf: file)
    let header = """
        \(MultipartBoundary)
        Content-Disposition: form-data; name="file"; filename="\(file.basename())"
        Content-Type: \(file.mimeType ?? "application/octet-stream")


        """
    guard let headerData = header.data(using: .utf8) else {
        throw ResterError.internalError("failed to encode multipart file header for file \(file)")
    }
    return headerData + data
}
