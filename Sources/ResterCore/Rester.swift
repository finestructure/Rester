//
//  Rester.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 03/02/2019.
//

import Foundation
import Gen
import Path
import Yams


public class Rester {
    public var requests: [Request] { return _requests }

    let restfile: Restfile
    var variables = [Key: Value]()
    let _requests: [Request]
    let _setupRequests: [Request]
    var setupRequests: [Request] { return _setupRequests }
    // FIXME: make private again after removing Rester+deprecated.swift
    internal var _cancel: Bool = false

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
    public func test(before: @escaping (Request.Name) -> (),
                     after: @escaping (TestResult) -> Void,
                     timeout: TimeInterval = Request.defaultTimeout,
                     validateCertificate: Bool = true,
                     runSetup: Bool = true) async throws -> [TestResult] {

        func process(requests: [Request]) async throws -> [TestResult] {
            var results = [TestResult]()
            for req in requests {
                before(req.name)
                guard req.shouldExecute(given: variables) else {
                    // FIXME: after(..., Response?, ...) ?
                    let result = TestResult.skipped(req.name)
                    after(result)
                    results.append(result)
                    return results
                }

                let resolved = try req.substitute(variables: variables)
                let response = try await resolved.execute(
                    timeout: timeout, validateCertificate: validateCertificate
                )
                variables = variables.processMutations(values: response.variables)
                variables[req.name] = response.variables
                let result = resolved.validate(response)
                let testResult = TestResult(name: req.name, validationResult: result, response: response)
                results.append(testResult)
                after(testResult)
            }
            return results
        }

        let toProcess: [Request]

        if mode == .random {
            let rnd = Gen.element(of: requests)
            guard let chosenRequest = rnd.run(using: &Current.rng) else {
                throw ResterError.internalError("failed to choose random request")
            }
            toProcess = [chosenRequest]
        } else {
            toProcess = requests
        }

        if runSetup {
            _ = try await process(requests: setupRequests)
        }

        return try await process(requests: toProcess)
    }

    public func cancel() {
        _cancel = true
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
