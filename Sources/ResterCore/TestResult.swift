//
//  TestResult.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 17/04/2019.
//

import Foundation


public enum TestResult: Equatable {
    case success(Request.Name, Response)
    case failure(Request.Name, Response, Reason)
    case skipped(Request.Name)

    init(name: Request.Name, validationResult: ValidationResult, response: Response) {
        switch validationResult {
            case .valid:
                self = .success(name, response)
            case .invalid(let reason):
                self = .failure(name, response, reason)
        }
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    var isSkipped: Bool {
        if case .skipped = self { return true }
        return false
    }

    var name: String {
        switch self {
            case let .success(name, _):
                return name
            case let .failure(name, _, _):
                return name
            case let .skipped(name):
                return name
        }
    }
}


extension Array where Element == TestResult {
    var successCount: Int { return filter { $0.isSuccess }.count }
    var failureCount: Int { return filter { $0.isFailure }.count }
    var skippedCount: Int { return filter { $0.isSkipped }.count }
}
