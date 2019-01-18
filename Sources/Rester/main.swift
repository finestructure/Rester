import Foundation
import Yams
import Regex


let decoder = YAMLDecoder()

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


typealias Key = String

enum Value: Equatable {
    case int(Int)
    case string(String)
}

extension Value: CustomStringConvertible {
    var description: String {
        switch self {
        case .int(let v):
            return String(v)
        case .string(let v):
            return v
        }
    }
}

typealias Variables = [Key: Value]

extension Value: Codable {
    init(from decoder: Decoder) throws {
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
}

struct Rester: Codable {
    let variables: Variables?
    let requests: [String: Request]?
}

struct Request: Codable {
    let url: String
    let method: Method
    let validation: Validation

    func substitute(variables: Variables) throws -> Request {
        let _url = try _substitute(string: url, with: variables)
        return Request(url: _url, method: method, validation: validation)
    }
}

struct Validation: Codable {
    let status: Int
}

enum Method: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}


let env = try decoder.decode(Rester.self, from: """
    variables:
        INT_VALUE: 42
        STRING_VALUE: some string value
""")

dump(env)

let req = try decoder.decode(Rester.self, from: """
    variables:
        API_URL: "https://dev.vbox.space"
    requests:
        version:
            url: ${API_URL}/metrics/build
            method: GET
            validation:
                status: 200
                content:
                    version: .regex('\\d+\\.\\d+\\.\\d+|\\S{40}')
""")

dump(req)

let variables = req.variables!
let requests = req.requests!
let versionReq = try requests["version"]!.substitute(variables: variables)

assert(variables["API_URL"]! == .string("https://dev.vbox.space"))
assert(versionReq.url == "https://dev.vbox.space/metrics/build", "was: \(versionReq.url)")

// TODO: parse validation.content


let vars: Variables = ["API_URL": .string("https://foo.bar"), "foo": .int(5)]
let n = try _substitute(string: "${API_URL}/metrics/build/${foo}/${foo}", with: vars)
print("result: \(n)")
