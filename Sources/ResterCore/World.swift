//
//  World.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 11/02/2019.
//
//  Motivation: https://www.pointfree.co/blog/posts/21-how-to-control-the-world
//

import Foundation


struct World {
    var environment = ProcessInfo.processInfo.environment
}


#if DEBUG
var Current = World()
#else
let Current = World()
#endif
