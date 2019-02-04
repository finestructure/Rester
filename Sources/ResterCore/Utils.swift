//
//  Utils.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 04/02/2019.
//

import Foundation


func _autoreleasepool(block: () -> ()) {
    #if os(Linux)
    block()
    #else
    autoreleasepool { block() }
    #endif
}


public func wait(timeout: TimeInterval, condition: () -> Bool) {
    #if os(Linux)
    let runLoopModes = [RunLoopMode.defaultRunLoopMode, RunLoopMode.commonModes]
    #else
    let runLoopModes = [RunLoop.Mode.default, RunLoop.Mode.common]
    #endif

    let pollingInterval: TimeInterval = 0.01
    let endDate = NSDate(timeIntervalSinceNow: timeout)
    var index = 0

    while !condition() {
        let mode = runLoopModes[index % runLoopModes.count]
        let checkDate = Date(timeIntervalSinceNow: pollingInterval)
        index += 1

        _autoreleasepool {
            if !RunLoop.current.run(mode: mode, before: checkDate) {
                Thread.sleep(forTimeInterval: pollingInterval)
            }
        }

        if endDate.compare(Date()) == .orderedAscending {
            break
        }
    }
}
