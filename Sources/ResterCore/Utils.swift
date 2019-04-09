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


public func forever<T>(interval: DispatchTimeInterval = .seconds(2), _ body: @escaping () -> Promise<T>) -> Promise<T> {
    func loop() -> Promise<T> {
        return body().then { _ in
            return after(interval).then(on: nil, loop)
        }
    }
    return loop()
}
