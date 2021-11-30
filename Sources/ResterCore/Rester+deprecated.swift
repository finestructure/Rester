import Foundation
import Gen
import PromiseKit


extension Rester {

    @available(*, deprecated)
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
                    guard !self._cancel else {
                        requests.forEach({ $0.cancel() })
                        return Promise<Void> { seal in seal.reject(PMKError.cancelled) }
                    }
                    before(req.name)
                    guard req.shouldExecute(given: self.variables) else {
                        // FIXME: after(..., Response?, ...) ?
                        let res = after(req.name, .skipped(req.name))
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
                            let testResult = TestResult(name: req.name, validationResult: result, response: response)
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

