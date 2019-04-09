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
        Average:   \(durations.average.ms)
        Median:    \(durations.median.ms)
        Min:       \(durations.min()?.ms ?? "-")
        Max:       \(durations.max()?.ms ?? "-")
        90% Pctl:  \(durations.percentile(0.9).ms)
        """
    }
}


extension Double {
    public var ms: String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        formatter.roundingMode = .halfUp
        return (formatter.string(from: NSNumber(value: self)) ?? "-") + " s"
    }
}


// TODO: move to Collection+ext

extension Collection where Element == Double {
    public var average: Element {
        let total = reduce(0, +)
        return isEmpty ? 0 : total / Element(count)
    }
}

extension Collection where Element == Double {
    public var median: Element {
        let s = sorted()
        if count.isMultiple(of: 2) {
            return [s[count/2 - 1], s[count/2]].average
        } else {
            return s[count/2]
        }
    }
}

extension Collection where Element == Double {
    public func percentile(_ p: Double) -> Element {
        let s = sorted()
        let cutoff = p.clamp(max: 1.0) * Double(count)
        let index = Int(cutoff)
        if index == count {
            return s[index - 1]
        } else if Double(index) == cutoff {
            return [s[index - 1], s[index]].average
        } else {
            return s[index]
        }
    }
}


extension Numeric where Self: Comparable {
    public func clamp(max: Self) -> Self {
        return min(self, max)
    }
}
