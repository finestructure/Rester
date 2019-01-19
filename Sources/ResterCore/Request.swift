//
//  Request.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation
import PromiseKit
import PMKFoundation


public struct Request: Codable {
    public let url: String
    public let method: Method
    public let validation: Validation
}


public struct Validator {
    let data: Data
    let response: HTTPURLResponse
}

extension Request {
    public func substitute(variables: Variables) throws -> Request {
        let _url = try _substitute(string: url, with: variables)
        return Request(url: _url, method: method, validation: validation)
    }

    public func execute() throws -> Promise<Validator> {
        guard let url = URL(string: url) else { throw ResterError.invalidURL(self.url) }

        return URLSession.shared.dataTask(.promise, with: url)
            .map { Validator(data: $0.data, response: $0.response as! HTTPURLResponse) }
    }
}
