//
//  Rester.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 03/02/2019.
//

import Foundation
import Path
import PromiseKit
import Yams


public struct Rester {
    let restfile: Restfile
    public var allVariables: [Key: Value]
    let allRequests: [Request]

    public init(path: Path, workDir: Path = Path.cwd) throws {
        if !path.exists {
            throw ResterError.fileNotFound(path.string)
        }
        let s = try String(contentsOf: path)
        try self.init(yml: s, workDir: workDir)
    }

    init(yml: String, workDir: Path = Path.cwd) throws {
        let r = try YAMLDecoder().decode(Restfile.self, from: yml, userInfo: [.relativePath: workDir])

        allVariables = aggregate(variables: r.variables, from: r.restfiles)
        allRequests = aggregate(requests: r.requests, from: r.restfiles)

        restfile = r
    }
}


extension Rester {
    public var requestCount: Int { return allRequests.count }
}


extension Rester {
    public func test<T>(
        before: @escaping (Request.Name) -> (),
        after: @escaping (Request.Name, Response, ValidationResult) -> T,
        timeout: TimeInterval = Request.defaultTimeout
        ) -> Promise<[T]> {

        var results = [T]()
        var jsonResponses = [Key: Value]()
        var chain = Promise()
        for req in allRequests {
            chain = chain.then { _ -> Promise<Void> in
                before(req.name)
                let variables = self.allVariables.merging(jsonResponses, strategy: .lastWins)
                let resolved = try req.substitute(variables: variables)
                return try resolved
                    .execute(timeout: timeout)
                    .map { response -> (Response, ValidationResult) in
                        if let json = response.json {
                            jsonResponses[req.name] = json
                        }
                        return (response, resolved.validate(response))
                    }.map { response, result in
                        let res = after(req.name, response, result)
                        results.append(res)
                }
            }
        }
        return chain.map { results }
    }
}
