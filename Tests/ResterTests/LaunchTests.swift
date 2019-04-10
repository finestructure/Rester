//
//  LaunchTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest
import SnapshotTesting


class LaunchTests: SnapshotTestCase {

    func test_launch_binary() throws {
        let requestFile = try path(example: "basic.yml").unwrapped()
        let (status, output) = try launch(with: requestFile)

        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_verbose() throws {
        let requestFile = try path(example: "basic.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["-v", "-t", "7"])

        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_malformed() throws {
        let requestFile = try path(fixture: "malformed.yml").unwrapped()
        let (status, output) = try launch(with: requestFile)

        XCTAssert(status == 1, "exit status not 1, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_loop_termination() throws {
        // ensure a bad file terminates the loop
        let requestFile = try path(fixture: "loop-error.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["--loop", "2"])

        XCTAssert(status == 1, "exit status not 1, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_loop_duration() throws {
        let requestFile = try path(example: "basic.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["-l", "1", "-d", "2"])
        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_stats() throws {
        let requestFile = try path(example: "basic2.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["--stats"])
        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }
    
}
