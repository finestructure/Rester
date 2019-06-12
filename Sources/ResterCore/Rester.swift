//
//  Rester.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 03/02/2019.
//

import Foundation
import Gen
import Path
import PromiseKit
import Yams


public class Rester {
    public var requests: [Request] { return _requests }

    let restfile: Restfile
    var variables = [Key: Value]()
    let _requests: [Request]
    let _setupRequests: [Request]
    var setupRequests: [Request] { return _setupRequests }

    /// Execution mode, determined by top level restfile
    var mode: Mode { return restfile.mode }

    public convenience init(path: Path, workDir: Path = Path.cwd) throws {
        if !path.exists {
            throw ResterError.fileNotFound(path.string)
        }
        let s = try String(contentsOf: path)
        try self.init(yml: s, workDir: workDir)
    }

    public init(yml: String, workDir: Path = Path.cwd) throws {
        let r = try YAMLDecoder().decode(Restfile.self, from: yml, userInfo: [.relativePath: workDir])

        variables = aggregate(variables: r.variables, from: r.restfiles)
        _requests = r.requests + aggregate(keyPath: \.requests, from: r.restfiles)
        _setupRequests = r.setupRequests + aggregate(keyPath: \.setupRequests, from: r.restfiles)

        restfile = r
    }
}


extension Rester {
    public func test<T>(before: @escaping (Request.Name) -> (),
                        after: @escaping (Request.Name, TestResult) -> T,
                        timeout: TimeInterval = Request.defaultTimeout,
                        validateCertificate: Bool = true,
                        runSetup: Bool = true
        ) -> Promise<[T]> {

        func process(requests: [Request]) -> Promise<[T]> {
            var results = [T]()
            var chain = Promise()
            for req in requests {
                chain = chain.then { _ -> Promise<Void> in
                    before(req.name)
                    guard req.shouldExecute(given: self.variables) else {
                        // FIXME: after(..., Response?, ...) ?
                        let res = after(req.name, .skipped)
                        results.append(res)
                        return Promise()
                    }
                    let resolved = try req.substitute(variables: self.variables)
                    return try resolved
                        .execute(timeout: timeout, validateCertificate: validateCertificate)
                        .map { response -> (Response, ValidationResult) in
                            self.variables = self.variables.processMutations(values: response.variables)
                            self.variables[req.name] = response.variables
                            return (response, resolved.validate(response))
                        }.map { response, result in
                            let testResult = TestResult(validationResult: result, response: response)
                            let res = after(req.name, testResult)
                            results.append(res)
                    }
                }
            }
            return chain.map { results }
        }

        let toProcess: [Request]

        if mode == .random {
            let rnd = Gen.element(of: requests)
            guard let chosenRequest = rnd.run(using: &Current.rng) else {
                let err = ResterError.internalError("failed to choose random request")
                return Promise(error: err)
            }
            toProcess = [chosenRequest]
        } else {
            toProcess = requests
        }

        if runSetup {
            return process(requests: setupRequests).then { _ in
                process(requests: toProcess)
            }
        } else {
            return process(requests: toProcess)
        }
    }

}


func aggregate(variables: [Key: Value], from restfiles: [Restfile]) -> [Key: Value] {
    return restfiles.map({ $0.variables }).reduce(variables) { aggregate, next in
        aggregate.merging(next, strategy: .lastWins)
    }
}


func aggregate(keyPath: KeyPath<Restfile, [Request]>, from restfiles: [Restfile]) -> [Request] {
    return restfiles.map { $0[keyPath: keyPath] }.reduce([], +)
}
