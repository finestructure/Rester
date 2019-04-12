//
//  Utils.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 04/02/2019.
//

import Foundation
import Path
import PromiseKit


public func getWorkDir(input: String) -> Path? {
    guard !input.isEmpty else { return nil }

    if let path = Path(input) {
        return path
    }

    // take is as relative path
    return Path.cwd/input
}


public func format(_ timeInterval: TimeInterval) -> String? {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.minimumFractionDigits = 3
    formatter.maximumFractionDigits = 3
    formatter.roundingMode = .halfUp
    return formatter.string(from: NSNumber(value: timeInterval))
}


public enum LoopCondition {
    case forever
    case end(Date)
    case times(Int)

    public init(seconds: Double) {
        self = .end(Date().addingTimeInterval(TimeInterval(seconds)))
    }

    public var done: Bool {
        switch self {
        case .forever:
            return false
        case .end(let date):
            return Date().timeIntervalSince(date) > 0
        case .times(let count):
            return count == 0
        }
    }

    public var incremented: LoopCondition {
        switch self {
        case .times(let count):
            return .times(count - 1)
        case .forever, .end:
            return self
        }
    }
}


public func run<T>(_ until: LoopCondition, interval: DispatchTimeInterval = .seconds(2), _ body: @escaping () -> Promise<T>) -> Promise<T> {
    var until = until
    func loop() -> Promise<T> {
        until = until.incremented
        if until.done {
            return body()
        }
        return body().then { res in
            return after(interval).then(on: nil, loop)
        }
    }
    return loop()
}
