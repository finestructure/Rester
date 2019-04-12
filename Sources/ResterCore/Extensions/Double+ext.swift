//
//  Double+ext.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 12/04/2019.
//

import Foundation


extension Double {
    public var seconds: DispatchTimeInterval {
        return .nanoseconds(Int(self * 1e9))
    }
}
