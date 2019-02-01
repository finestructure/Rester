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
    typealias Name = String

    struct Details: Decodable {
        let url: String
        let method: Method?
        let body: Body?
        let validation: Validation?
    }

    public let name: String
    let details: Details

    public var url: String { return details.url }
    public var method: Method { return details.method ?? .get }
    public var body: Body? { return details.body }
    public var validation: Validation? { return details.validation }
}


extension Request: Substitutable {
    func substitute(variables: [Key: Value]) throws -> Request {
        let _url = try ResterCore.substitute(string: url, with: variables)
        let _body = try body?.substitute(variables: variables)
        let _details = Details(url: _url, method: method, body: _body, validation: validation)
        return Request(name: name, details: _details)
    }
}


extension Request {
    public func execute(debug: Bool = false) throws -> Promise<Response> {
        guard let url = URL(string: url) else { throw ResterError.invalidURL(self.url) }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        if method == .post {
            if
                let body = body?.json,
                let postData = try? JSONEncoder().encode(body) {
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = postData
            } else if
                let body = body?.form?.formUrlEncoded,
                let postData = body.data(using: .utf8) {
                urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = postData
                if debug {
                    print("Request:")
                    dump(urlRequest)
                    print("Body:")
                    dump(body)
                }
            }
        }

        return URLSession.shared.dataTask(.promise, with: urlRequest)
            .map { Response(data: $0.data, response: $0.response as! HTTPURLResponse) }
    }

    public func test() throws -> Promise<ValidationResult> {
        return try execute().map { self.validate($0) }
    }

    public func validate(_ response: Response) -> ValidationResult {
        if
            let status = validation?.status,
            case let .invalid(msg, _) = status.validate(Value.int(response.status)) {
            return .invalid("status invalid: \(msg)", response: response)
        }

        if let json = validation?.json {
            // assume Dictionary response
            // TODO: handle Array response
            guard let data = try? JSONDecoder().decode([Key: Value].self, from: response.data)
                else {
                    return .invalid("failed to decode JSON object from response", response: response)
            }

            // TODO: make json a Matcher to begin with
            let matcher = Matcher.contains(json)
            if case let .invalid(msg, _) = matcher.validate(Value.dictionary(data)) {
                return .invalid("json invalid: \(msg)", response: response)
            }
        }
        return .valid
    }
}


extension Array where Element == Request {
    subscript(requestName: String) -> Request? {
        return first(where: { $0.name == requestName } )
    }
}
