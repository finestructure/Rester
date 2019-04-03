//
//  Request.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import PMKFoundation
import PromiseKit
import Regex


public struct Request: Decodable {
    public static let defaultTimeout: TimeInterval = 5

    public typealias Name = String
    typealias Headers = [Key: Value]
    typealias QueryParameters = [Key: Value]

    struct Details: Decodable {
        let url: String
        let method: Method?
        let headers: Headers?
        let query: QueryParameters?
        let body: Body?
        let validation: Validation?
        let delay: Value?
        let log: Value?
    }

    let name: Name
    let details: Details

    init(name: Name, details: Details) {
        self.name = name
        self.details = details
    }
}


// convenience accessors
extension Request {
    var method: Method { return details.method ?? .get }
    var headers: Headers { return details.headers ?? [:] }
    var query: QueryParameters { return details.query ?? [:] }
    var body: Body? { return details.body }
    var validation: Validation? { return details.validation }
    var delay: TimeInterval {
        guard let value = details.delay else { return 0 }
        switch value {
        case let .int(value):
            return TimeInterval(value)
        case let .double(value):
            return value
        case let .string(value):
            if let v = Int(value) { return TimeInterval(v) }
            else if let v = Double(value) { return v }
            else { return 0 }
        default:
            return 0
        }
    }
    var log: Value? { return details.log }

    var url: URL? {
        var components = URLComponents(string: details.url)
        components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value.string) }
        return components?.url
    }
}


extension Request: Substitutable {
    func substitute(variables: [Key: Value]) throws -> Request {
        let _url = try ResterCore.substitute(string: details.url, with: variables)
        let _headers = try headers.substitute(variables: variables)
        let _query = try query.substitute(variables: variables)
        let _body = try body?.substitute(variables: variables)
        let _validation = try validation?.substitute(variables: variables)
        let _delay = try details.delay?.substitute(variables: variables)
        let _details = Details(
            url: _url,
            method: method,
            headers: _headers,
            query: _query,
            body: _body,
            validation: _validation,
            delay: _delay,
            log: log
        )
        return Request(name: name, details: _details)
    }
}


extension Request {
    public func execute(timeout: TimeInterval = Request.defaultTimeout, validateCertificate: Bool = true) throws -> Promise<Response> {
        guard let url = url else { throw ResterError.invalidURL(self.details.url) }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        if [.post, .put].contains(method), let body = body {
            switch body {
            case let .json(body):
                if let postData = try? JSONEncoder().encode(body) {
                    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = postData
                }
            case let .form(body):
                if let postData = body.formUrlEncoded.data(using: .utf8) {
                    urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = postData
                }
            case let .multipart(body):
                urlRequest.addValue(
                    "multipart/form-data; charset=utf-8; boundary=__X_RESTER_BOUNDARY__",
                    forHTTPHeaderField: "Content-Type"
                )
                urlRequest.httpBody = try body.multipartEncoded()
            case let .text(body):
                urlRequest.addValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = body.data(using: .utf8)
            case let .file(file):
                let path = try file.path()
                urlRequest.addValue(path.mimeType, forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = try Data(contentsOf: path)
            }
        }
        headers.forEach {
            urlRequest.addValue($0.value.string, forHTTPHeaderField: $0.key)
        }

        if delay > 0 {
            Current.console.display(verbose: "Delaying for \(delay)s")
        }

        // NB: URLSession keeps a strong reference to the delegate, so we don't need to keep it around ourselves
        let delegate = SessionDelegate(validateCertificate: validateCertificate)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: .main)

        let request = after(seconds: delay)
            .then { () -> Promise<(start: Date, response: (data: Data, response: URLResponse))> in
                let start = Date()
                return session.dataTask(.promise, with: urlRequest).map { (start: start, response: $0)}
            }.map {
                Response(
                    elapsed: Date().timeIntervalSince($0.start),
                    data: $0.response.data,
                    response: $0.response.response as! HTTPURLResponse
                )
            }.map { Result<Response>.fulfilled($0) }

        let timeout: Promise<Result<Response>> = after(seconds: delay + timeout).map { _ in
            .rejected(ResterError.timeout(requestName: self.name))
        }

        return race(request, timeout)
            .map { winner -> Response in
                switch winner {
                case .fulfilled(let result):
                    return result
                case .rejected(let error):
                    throw error
                }
            }.map { response in
                if let value = self.log { try _log(value: value, of: response) }
                return response
        }
    }

    public func test() throws -> Promise<ValidationResult> {
        return try execute().map { self.validate($0) }
    }

    public func validate(_ response: Response) -> ValidationResult {
        if
            let status = validation?.status,
            case let .invalid(msg) = status.validate(Value.int(response.status)) {
            return .invalid("status invalid: \(msg)")
        }

        if
            let headers = validation?.headers,
            case let .invalid(msg) = headers.validate(Value.dictionary(response.headers)) {
            return .invalid("status invalid: \(msg)")
        }

        if let jsonMatcher = validation?.json {
            if let json = response.json {
                if case let .invalid(msg) = jsonMatcher.validate(json) {
                    return .invalid("json invalid: \(msg)")
                }
            } else {
                return .invalid("failed to decode JSON object from response")
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


func _log(value: Value, of response: Response) throws {
    switch value {
    case .bool(true):
        try ["status", "headers", "json"].forEach { try _log(value: $0, of: response) }
    case .string("status"):
        Current.console.display(key: "Status", value: response.status)
    case .string("headers"):
        Current.console.display(key: "Headers", value: response.headers)
    case let .string(keyPath) where keyPath.starts(with: "json."),
         let .string(keyPath) where keyPath.starts(with: "json["):
        guard let json = response.json else { return }
        let res = Value.dictionary(["json": json])
        if let value = res[keyPath] {
            let displayKeyPath = keyPath.deletingPrefix("json").deletingPrefix(".")
            Current.console.display(key: displayKeyPath, value: value)
        }
    case .string("json"):
        if let json = response.json {
            Current.console.display(key: "JSON", value: json)
        }
    case .string where (try? value.path()) != nil:      // a bit clumsy but can't see how to
        try response.data.write(to: try value.path())   // avoid the double call to path()
    case let .array(array) where !array.isEmpty:
        for item in array {
            try _log(value: item, of: response)
        }
    default:
        break
    }
}


extension Request {
    class SessionDelegate: NSObject, URLSessionDelegate {
        let validateCertificate: Bool

        init(validateCertificate: Bool = true) {
            self.validateCertificate = validateCertificate
        }

        func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if validateCertificate {
                completionHandler(.performDefaultHandling, nil)
            } else {
                // trust certificate
                let cred = challenge.protectionSpace.serverTrust.map { URLCredential(trust: $0) }
                completionHandler(.useCredential, cred)
            }
        }
    }
}
