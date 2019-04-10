//
//  Collection+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 10/04/2019.
//

import Foundation


extension Collection where Element == Double {
    public var average: Element {
        let total = reduce(0, +)
        return isEmpty ? .nan : total / Element(count)
    }
}


extension Collection where Element == Double {
    public var median: Element {
        guard !isEmpty else { return .nan }
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
        guard count >= 2 else { return .nan }
        let s = sorted()
        let cutoff = abs(p).clamp(max: 0.99) * Double(count)
        let index = Int(cutoff)
        let isInteger = (Double(index) == cutoff)
        if isInteger {
            guard (1..<count).contains(index) else { return .nan }
            return [s[index - 1], s[index]].average
        } else {
            return s[index]
        }
    }
}


extension Collection where Element == Double {
    public var stddev: Element {
        guard count > 0 else { return .nan }
        let mean = average
        let sumOfMeanSqr = map { pow($0 - mean, 2) }.reduce(0, +)
        let variance = sumOfMeanSqr / Double(count - 1)
        return sqrt(variance)
    }
}
