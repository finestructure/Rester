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


public class Rester {
    public var variables: [Key: Value] { return _variables }
    public var requests: [Request] { return _requests }

    let restfile: Restfile
    let _requests: [Request]
    let _variables: [Key: Value]
    var responses = [Key: Value]()

    public convenience init(path: Path, workDir: Path = Path.cwd) throws {
        if !path.exists {
            throw ResterError.fileNotFound(path.string)
        }
        let s = try String(contentsOf: path)
        try self.init(yml: s, workDir: workDir)
    }

    init(yml: String, workDir: Path = Path.cwd) throws {
        let r = try YAMLDecoder().decode(Restfile.self, from: yml, userInfo: [.relativePath: workDir])

        _variables = aggregate(variables: r.variables, from: r.restfiles)
        _requests = aggregate(requests: r.requests, from: r.restfiles)

        restfile = r
    }
}


extension Rester {
    public func test<T>(before: @escaping (Request.Name) -> (),
                        after: @escaping (Request.Name, Response, ValidationResult) -> T,
                        timeout: TimeInterval = Request.defaultTimeout,
                        validateCertificate: Bool = true
        ) -> Promise<[T]> {

        var results = [T]()
        var chain = Promise()
        for req in requests {
            chain = chain.then { _ -> Promise<Void> in
                before(req.name)
                let variables = self.variables.merging(self.responses, strategy: .lastWins)
                let resolved = try req.substitute(variables: variables)
                return try resolved
                    .execute(timeout: timeout, validateCertificate: validateCertificate)
                    .map { response -> (Response, ValidationResult) in
                        if let json = response.json {
                            self.responses[req.name] = json
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
