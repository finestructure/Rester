//
//  World.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 11/02/2019.
//
//  Motivation: https://www.pointfree.co/blog/posts/21-how-to-control-the-world
//

import Foundation
import Gen
import Path


public struct World {
    public var console: Console = DefaultConsole()
    public var environment = ProcessInfo.processInfo.environment
    public var workDir = Path.cwd
    var rng = AnyRandomNumberGenerator(SystemRandomNumberGenerator())
}


public var Current = World()
