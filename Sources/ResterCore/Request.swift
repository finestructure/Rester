//
//  Request.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import PromiseKit
import PMKFoundation
import AnyCodable
import Regex


public struct Request: Decodable {
    public let name: String
    let details: RequestDetails

    public var url: String { return details.url }
    public var method: Method { return details.method }
    public var validation: Validation { return details.validation }
}


public struct Response {
    let data: Data
    let response: HTTPURLResponse

    var status: Int {
        return response.statusCode
    }
}


public enum ValidationResult: Equatable {
    case valid
    case invalid(String)
}


extension Request {
    public func substitute(variables: Variables) throws -> Request {
        let _url = try _substitute(string: url, with: variables)
        let _details = RequestDetails(url: _url, method: method, validation: validation)
        return Request(name: name, details: _details)
    }

    public func execute() throws -> Promise<Response> {
        guard let url = URL(string: url) else { throw ResterError.invalidURL(self.url) }

        return URLSession.shared.dataTask(.promise, with: url)
            .map { Response(data: $0.data, response: $0.response as! HTTPURLResponse) }
    }

    public func test() throws -> Promise<ValidationResult> {
        guard let url = URL(string: url) else { throw ResterError.invalidURL(self.url) }

        return URLSession.shared.dataTask(.promise, with: url)
            .map { Response(data: $0.data, response: $0.response as! HTTPURLResponse) }
            .map {
                self.validate($0)
        }
    }

    public func validate(_ response: Response) -> ValidationResult {
        if
            let status = validation.status,
            response.status != status {
            return .invalid("status invalid, expected '\(status)' was '\(response.response.statusCode)'")
        }

        if let json = validation.json {
            // assume Dictionary response
            // TODO: handle Array response
            guard let data = try? JSONDecoder().decode([Key: AnyCodable].self, from: response.data)
                else {
                    return .invalid("failed to decode JSON object from response")
            }

            for (key, matcher) in json {
                let res = _validate(matcher: matcher, key: key, data: data)
                if res != .valid { return res }
            }
        }
        return .valid
    }
}


func _validate(matcher: Matcher, key: Key, data: [Key: AnyCodable]) -> ValidationResult {
    guard let value = data[key] else { return .invalid("key '\(key)' not found in JSON response") }
    switch matcher {
    case .int(let expected):
        let res = equals(key: key, expected: expected, found: value)
        if res != .valid { return res }
    case .string(let expected):
        let res = equals(key: key, expected: expected, found: value)
        if res != .valid { return res }
    case .regex(let regex):
        let res = matches(key: key, regex: regex, found: value)
        if res != .valid { return res }
    }
    return .valid
}


func equals<T: Equatable>(key: Key, expected: T, found: AnyCodable) -> ValidationResult {
    guard let value = try? found.assertValue(T.self) else {
        return .invalid("json.\(key) expected to be of type \(T.self), was '\(found)'")
    }
    if value != expected {
        return .invalid("json.\(key) invalid, expected '\(expected)' was '\(value)'")
    }
    return .valid
}


func matches(key: Key, regex: Regex, found: AnyCodable) -> ValidationResult {
    guard let value = try? found.assertValue(String.self) else {
        return .invalid("json.\(key) expected to be of type \(String.self), was '\(found)'")
    }
    if value !~ regex {
        return .invalid("json.\(key) failed to match '\(regex.pattern)', was '\(value)'")
    }
    return .valid
}
