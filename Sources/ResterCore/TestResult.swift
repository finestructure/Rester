//
//  TestResult.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 17/04/2019.
//

import Foundation


public enum TestResult {
    case success(Response)
    case failure(Response, Reason)
    case skipped

    init(validationResult: ValidationResult, response: Response) {
        switch validationResult {
        case .valid:
            self = .success(response)
        case .invalid(let reason):
            self = .failure(response, reason)
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
}


extension Array where Element == TestResult {
    var successCount: Int { return filter { $0.isSuccess }.count }
    var failureCount: Int { return filter { $0.isFailure }.count }
    var skippedCount: Int { return filter { $0.isSkipped }.count }
}
