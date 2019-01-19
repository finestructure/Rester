import Foundation
import Regex

enum ResterError: Error {
    case decodingError(String)
    case undefinedVariable(String)
}

func _substitute(string: String, with variables: Variables) throws -> String {
    let regex = try Regex(pattern: "\\$\\{(.*?)\\}", groupNames: "variable")
    let res = regex.replaceAll(in: string) { match in
        if
            let varName = match.group(named: "variable"),
            let value = variables[varName]?.description {
            return value
        } else {
            return nil
        }
    }

    if res =~ regex {
        throw ResterError.undefinedVariable("Undefined variable: \(res)")
    }
    return res
}


public typealias Key = String

public enum Value: Equatable {
    case int(Int)
    case string(String)
}

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .int(let v):
            return String(v)
        case .string(let v):
            return v
        }
    }
}

public typealias Variables = [Key: Value]

extension Value: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // string decoding must be possible
        let stringValue = try container.decode(String.self)

        // strings with a colon get parsed as Int (with value 0) for some reason
        if !stringValue.contains(":"), let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }

        // default to string
        self = .string(stringValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
}

public struct Rester: Codable {
    public let variables: Variables?
    public let requests: [String: Request]?
}

public struct Request: Codable {
    public let url: String
    public let method: Method
    public let validation: Validation

    public func substitute(variables: Variables) throws -> Request {
        let _url = try _substitute(string: url, with: variables)
        return Request(url: _url, method: method, validation: validation)
    }
}

public struct Validation: Codable {
    let status: Int
}

public enum Method: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
