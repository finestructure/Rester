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

    // FIXME: remove when removing Rester+deprecated.swift
    internal var _cancel: Bool = false

    private var taskQueue = DispatchQueue(label: "taskQueue")
    private var _task: TaskStatus<[TestResult]> = .idle
    private var task: TaskStatus<[TestResult]> {
        get {
            taskQueue.sync {
                return _task
            }
        }
        set {
            taskQueue.async {
                guard !self._task.isCancelled else { return }
                self._task = newValue
            }
        }
    }

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
    private func _process(_ req: Request,
                          before: @escaping (Request.Name) -> (),
                          after: @escaping (TestResult) -> Void,
                          timeout: TimeInterval = Request.defaultTimeout,
                          validateCertificate: Bool = true) async throws -> TestResult {
        before(req.name)
        guard req.shouldExecute(given: variables) else {
            // FIXME: after(..., Response?, ...) ?
            let result = TestResult.skipped(req.name)
            after(result)
            return result
        }

        let resolved = try req.substitute(variables: variables)
        let response = try await resolved.execute(
            timeout: timeout, validateCertificate: validateCertificate
        )
        variables = variables.processMutations(values: response.variables)
        variables[req.name] = response.variables
        let result = resolved.validate(response)
        let testResult = TestResult(name: req.name, validationResult: result, response: response)
        after(testResult)
        return testResult
    }


    public func test(before: @escaping (Request.Name) -> (),
                     after: @escaping (TestResult) -> Void,
                     timeout: TimeInterval = Request.defaultTimeout,
                     validateCertificate: Bool = true,
                     runSetup: Bool = true) async throws -> [TestResult] {
        guard !task.isCancelled else {
            throw CancellationError()
        }

        task = .inProgress(Task {
            if runSetup {
                // TODO: use forEach instead
                _ = try await setupRequests.map {
                    try await _process($0, before: before, after: after, timeout: timeout, validateCertificate: validateCertificate)
                }
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

            return try await toProcess.map { req in
                do {
                    return try await _process(req, before: before, after: after, timeout: timeout, validateCertificate: validateCertificate)
                } catch let error as NSError where error.domain == "NSURLErrorDomain" && error.code == -1001 {
                    // convert URLSession timeout errors to ResterError
                    throw ResterError.timeout(requestName: req.name)
                }
            }
        })

        do {
            if let results = try await task.value {
                return results
            } else {
                // cancelled while in flight but before URLRequest was launched
                throw CancellationError()
            }
        } catch let error as NSError where error.domain == "NSURLErrorDomain" && error.code == -999 {
            // cancelled while in flight after URLRequest was launched
            throw CancellationError()
        }
    }

    public func cancel() {
        task.cancel()
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
