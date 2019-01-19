//
//  Request.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 19/01/2019.
//

import Foundation


public struct Request: Codable {
    public let url: String
    public let method: Method
    public let validation: Validation
}

extension Request {
    public func substitute(variables: Variables) throws -> Request {
        let _url = try _substitute(string: url, with: variables)
        return Request(url: _url, method: method, validation: validation)
    }

    public func execute(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: url) else {
            return completionHandler(nil, nil, ResterError.invalidURL(self.url))
        }
        URLSession.shared.dataTask(with: url, completionHandler: completionHandler).resume()
    }
}
