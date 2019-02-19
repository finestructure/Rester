//
//  LaunchTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest

class LaunchTests: XCTestCase {

    func test_launch_binary() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let binary = productsDirectory.appendingPathComponent("rester")
        let requestFile = path(for: "basic.yml")!

        let process = Process()
        process.executableURL = binary
        process.arguments = [requestFile.string]

        let pipe = Pipe()
        process.standardOutput = pipe

        #if os(Linux)
        process.launch()
        #else
        try process.run()
        #endif

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        let status = process.terminationStatus

        XCTAssert(
            output?.starts(with: "🚀  Resting") ?? false,
            "output start does not match, was: \(output ?? "")"
        )
        XCTAssert(
            status == 0,
            "exit status not 0, was: \(status), output: \(output ?? "")"
        )
    }

}
