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
    public var aggregatedVariables: [Key: Value]
    var expandedRequests: [Request]

    public init(path: Path, workDir: Path = Path.cwd) throws {
        if !path.exists {
            throw ResterError.fileNotFound(path.string)
        }
        let s = try String(contentsOf: path)
        try self.init(yml: s, workDir: workDir)
    }

    init(yml: String, workDir: Path = Path.cwd) throws {
        let r = try YAMLDecoder().decode(Restfile.self, from: yml, userInfo: [.relativePath: workDir])

        let aggregatedVariables = aggregate(variables: r.variables, from: r.restfiles)
        let aggregatedRequests = aggregate(requests: r.requests, from: r.restfiles)

        restfile = r

        expandedRequests = try aggregatedRequests.compactMap {
            try $0.substitute(variables: aggregatedVariables)
        }
        self.aggregatedVariables = aggregatedVariables
    }
}


extension Rester {
    public var requestCount: Int { return expandedRequests.count }
}


extension Rester {
    public func test(before: @escaping (Request.Name) -> (), after: @escaping (Request.Name, ValidationResult) -> ()) -> Promise<[ValidationResult]> {
        var results = [ValidationResult]()
        var chain = Promise()
        for req in expandedRequests {
            chain = chain.then { _ -> Promise<Void> in
                before(req.name)
                return try req.test().map { result in
                    after(req.name, result)
                    results.append(result)
                }
            }
        }
        return chain.map { results }
    }
}

extension Rester: Sequence {
    public func makeIterator() -> Rester.Iterator {
        return Iterator(self)
    }
}


extension Rester {
    public struct Iterator: IteratorProtocol {
        public typealias Element = Request

        let requests: [Request]
        var currentIndex = 0

        init(_ rester: Rester) {
            self.requests = rester.expandedRequests
        }

        public mutating func next() -> Request? {
            guard currentIndex < requests.count else {
                return nil
            }
            let req = requests[currentIndex]
            currentIndex += 1
            return req
        }
    }
}
