//
//  LaunchTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest
import Path
import Regex


@testable import ResterCore


enum TestError: Error {
    case runtimeError(String)
}


func maskTime(_ string: String) throws -> String {
    let regex = try Regex(pattern: "\\(\\d+\\.?\\d*s\\)")
    return regex.replaceAll(in: string, with: "(X.XXXs)")
}


func launch(with requestFile: Path, extraArguments: [String] = []) throws -> (status: Int32, output: String) {
    // Some of the APIs that we use below are available in macOS 10.13 and above.
    guard #available(macOS 10.13, *) else {
        throw TestError.runtimeError("unsupported OS")
    }

    let binary = productsDirectory.appendingPathComponent("rester")

    let process = Process()
    process.executableURL = binary
    process.arguments = [requestFile.string] + extraArguments

    let pipe = Pipe()
    process.standardOutput = pipe

    #if os(Linux)
    process.launch()
    #else
    try process.run()
    #endif

    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = try maskTime(String(data: data, encoding: .utf8) ?? "no output")
    let status = process.terminationStatus

    return (status, output)
}


class LaunchTests: XCTestCase {

    func test_mask_time() throws {
        XCTAssertEqual(try maskTime("basic PASSED (0.01s)"), "basic PASSED (X.XXXs)")
        XCTAssertEqual(try maskTime("basic PASSED (0s)"), "basic PASSED (X.XXXs)")
    }

    func test_launch_binary() throws {
        let requestFile = path(for: "basic.yml")!
        let (status, output) = try launch(with: requestFile)

        XCTAssert(
            status == 0,
            "exit status not 0, was: \(status), output: \(output)"
        )

        let expected = """
            🚀  Resting \(requestFile.string) ...

            🎬  basic started ...

            ✅  basic PASSED (X.XXXs)

            Executed 1 tests, with 0 failures

            """
        XCTAssertEqual(output, expected)
    }

    func test_launch_binary_verbose() throws {
        let requestFile = path(for: "basic.yml")!
        let (status, output) = try launch(with: requestFile, extraArguments: ["-v", "-t", "7"])

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

        ✅  basic PASSED (X.XXXs)

        Executed 1 tests, with 0 failures

        """
        XCTAssertEqual(output, expected)
    }

    func test_launch_binary_malformed() throws {
        let requestFile = path(for: "malformed.yml")!
        let (status, output) = try launch(with: requestFile)

        XCTAssert(
            status == 1,
            "exit status not 0, was: \(status), output: \(output)"
        )

        let expected = """
        🚀  Resting \(requestFile.string) ...

        ❌  Restfile syntax error: key not found: url

        """
        XCTAssertEqual(output, expected)
    }

}
