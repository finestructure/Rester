//
//  Numeric+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 10/04/2019.
//

import Foundation


extension Numeric where Self: Comparable {
    public func clamp(max: Self) -> Self {
        return min(self, max)
    }
}
