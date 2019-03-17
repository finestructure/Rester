//
//  LaunchTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest
import Path
import SnapshotTesting


@testable import ResterCore


class LaunchTests: SnapshotTestCase {

    func test_mask_time() throws {
        XCTAssertEqual("basic PASSED (0.01s)".maskTime, "basic PASSED (X.XXXs)")
        XCTAssertEqual("basic PASSED (0s)".maskTime, "basic PASSED (X.XXXs)")
    }

    func test_mask_path() throws {
        do {  // file
            let filePath = path(for: "basic.yml")!
            let input = "Resting \(filePath) ...\n\nreferencing the file again: \(filePath). Done."
            let output = "Resting basic.yml ...\n\nreferencing the file again: basic.yml. Done."
            XCTAssertEqual(input.maskPath(filePath), output)
        }
        do {  // directory
            let filePath = testDataDirectory()!
            let input = "Resting \(filePath) ...\n\nreferencing the file again: \(filePath). Done."
            let output = "Resting XXX ...\n\nreferencing the file again: XXX. Done."
            XCTAssertEqual(input.maskPath(filePath), output)
        }
    }

    func test_launch_binary() throws {
        let requestFile = path(for: "basic.yml")!
        let (status, output) = try launch(with: requestFile)

        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_verbose() throws {
        let requestFile = path(for: "basic.yml")!
        let (status, output) = try launch(with: requestFile, extraArguments: ["-v", "-t", "7"])

        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_malformed() throws {
        let requestFile = path(for: "malformed.yml")!
        let (status, output) = try launch(with: requestFile)

        XCTAssert(status == 1, "exit status not 1, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

}
