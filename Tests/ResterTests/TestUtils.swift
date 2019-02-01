//
//  TestUtils.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 30/01/2019.
//

import Foundation
import Path


func path(for fixture: String) -> Path? {
    return testDataDirectory()?.join(fixture)
}


func readFixture(_ fixture: String) throws -> String? {
    guard let file = path(for: fixture) else { return nil }
    return try String(contentsOf: file)
}


var productsDirectory: URL {
    #if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
    }
    fatalError("couldn't find the products directory")
    #else
    return Bundle.main.bundleURL
    #endif
}


func testDataDirectory(path: String = #file) -> Path? {
    return Path(path)?.parent.join("TestData")
}
