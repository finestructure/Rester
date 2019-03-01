//
//  LaunchTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest

@testable import ResterCore


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
        let output = String(data: data, encoding: .utf8) ?? "no output"
        let status = process.terminationStatus

        XCTAssert(
            status == 0,
            "exit status not 0, was: \(status), output: \(output)"
        )

        let expected = """
            🚀  Resting \(requestFile.string) ...

            🎬  basic started ...

            ✅  basic PASSED

            Executed 1 tests, with 0 failures

            """
        XCTAssertEqual(output, expected)
    }

    func test_launch_binary_verbose() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        Current.console = PlainConsole()

        let binary = productsDirectory.appendingPathComponent("rester")
        let requestFile = path(for: "basic.yml")!

        let process = Process()
        process.executableURL = binary
        process.arguments = [requestFile.string, "-v", "-t", "7"]

        let pipe = Pipe()
        process.standardOutput = pipe

        #if os(Linux)
        process.launch()
        #else
        try process.run()
        #endif

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? "no output"
        let status = process.terminationStatus

        XCTAssert(
            status == 0,
            "exit status not 0, was: \(status), output: \(output)"
        )

        let expected = """
        🚀  Resting \(requestFile.string) ...

        Restfile path: \(requestFile.string)
        Working directory: \(testDataDirectory()!)

        Request timeout: 7.0s

        Defined variables:
          - API_URL

        🎬  basic started ...

        ✅  basic PASSED

        Executed 1 tests, with 0 failures

        """
        XCTAssertEqual(output, expected)
    }
}
