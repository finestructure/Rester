//
//  Stats.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 09/04/2019.
//

import Foundation


public struct Stats {
    public var durations = [TimeInterval]()

    public mutating func add(_ duration: TimeInterval) {
        durations.append(duration)
    }
}


extension Stats: CustomStringConvertible {
    public var description: String {
        return """
        Average:   \(durations.average.fmt)
        Median:    \(durations.median.fmt)
        Min:       \(durations.min()?.fmt ?? "-")
        Max:       \(durations.max()?.fmt ?? "-")
        Std dev:   \(durations.stddev.fmt)
        90% Pctl:  \(durations.percentile(0.9).fmt)
        """
    }
}


extension Double {
    fileprivate var fmt: String {
        guard !isNaN else { return "-" }
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        formatter.roundingMode = .halfUp
        guard let str = formatter.string(from: NSNumber(value: self)) else { return "-" }
        return str + "s"
    }
}
