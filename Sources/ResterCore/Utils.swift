import Foundation
import Path


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


func iterationParameters(count: Int?, duration: Double?) -> Iteration? {
    switch (count, duration) {
    case let (i?, .some):
        return .times(i)
    case let (i?, .none):
        return .times(i)
    case let (.none, d?):
        return Iteration(seconds: d)
    case (.none, .none):
        return nil
    }
}


func loopParameters(count: Int?, duration: Double?, loop: Double?) -> (iteration: Iteration, delay: Double)? {
    let iter = iterationParameters(count: count, duration: duration)
    switch (iter, loop) {
    case (.none, .none):
        return nil
    case let (.none, d?):
        return (.forever, d)
    case let (i?, .none):
        return (i, 0)
    case let (i?, d?):
        return (i, d)
    }
}


public enum Iteration {
    case forever
    case until(Date)
    case times(Int)

    public init(seconds: Double) {
        self = .until(Date().addingTimeInterval(TimeInterval(seconds)))
    }

    public var done: Bool {
        switch self {
        case .forever:
            return false
        case .until(let date):
            return Date().timeIntervalSince(date) > 0
        case .times(let count):
            return count == 0
        }
    }

    public var incremented: Iteration {
        switch self {
        case .times(let count):
            return .times(count - 1)
        case .forever, .until:
            return self
        }
    }
}

extension Iteration: Equatable {}


public func loop(_ iteration: Iteration, interval: TimeInterval = 2.0, _ body: @escaping () async -> Void) async throws -> Void {
    var iteration = iteration
    var firstLoop = true
    while !iteration.done {
        if !firstLoop {
            try await Task.sleep(seconds: interval)
        }
        firstLoop = false
        iteration = iteration.incremented
        await body()
    }
}


extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000.0))
    }
}
