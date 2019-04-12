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


public enum Duration {
    case forever
    case seconds(Double)

    var end: Date? {
        switch self {
        case .forever:
            return nil
        case .seconds(let sec):
            return Date().addingTimeInterval(TimeInterval(sec))
        }
    }
}


public func run<T>(_ duration: Duration, interval: DispatchTimeInterval = .seconds(2), _ body: @escaping () -> Promise<T>) -> Promise<T> {
    let end = duration.end
    func loop() -> Promise<T> {
        if let end = end, Date().timeIntervalSince(end) > 0 {
            return body()
        }
        return body().then { res in
            return after(interval).then(on: nil, loop)
        }
    }
    return loop()
}
