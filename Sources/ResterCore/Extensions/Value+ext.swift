//
//  Value.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Path
import Regex
import ValueCodable


public typealias Key = ValueCodable.Key
public typealias Value = ValueCodable.Value


extension Value: URLEncoding {
    var urlEncoded: String? {
        switch self {
        case .bool(let v):
            return v.description
        case .int(let v):
            return String(v).urlEncoded
        case .string(let v):
            return v.urlEncoded
        case .double(let v):
            return String(v).urlEncoded
        case .dictionary(let v):
            return v.formUrlEncoded
        case .array(let v):
            return "[" + v.compactMap { $0.urlEncoded }.joined(separator: ",") + "]"
        case .null:
            return "null"
        }
    }
}


extension Value: Substitutable {
    func substitute(variables: [Key : Value]) throws -> Value {
        switch self {
        case .string(let string):
            return try .string(ResterCore.substitute(string: string, with: variables))
        default:
            return self
        }
    }
}


extension Value {
    func path() throws -> Path {
        if case let .string(string) = self {
            // FIXME: deal with () in path names
            let regex = try Regex(pattern: ".file\\((.*?)\\)", groupNames: "file")
            guard
                let match = regex.findFirst(in: string),
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
        throw ResterError.internalError("extracting file requires string value, found: \(self)")
    }
}


extension Value {
    var isJSONReference: Bool {
        guard case let .string(string) = self else { return false }
        return string.starts(with: "json.") || string.starts(with: "json[")
    }

    var appendValue: String? {
        if
            case let .string(string) = self,
            let regex = try? Regex(pattern: #".append\((.*?)\)"#, groupNames: "variable"),
            let match = regex.findFirst(in: string),
            let varName = match.group(named: "variable") {
            return varName
        }
        return nil
    }
}
