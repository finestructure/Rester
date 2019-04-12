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
        XCTAssertEqual(status, 0)
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_verbose() throws {
        let requestFile = try path(example: "basic.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["-v", "-t", "7"])
        XCTAssertEqual(status, 0)
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_malformed() throws {
        let requestFile = try path(fixture: "malformed.yml").unwrapped()
        let (status, output) = try launch(with: requestFile)
        XCTAssertEqual(status, 1)
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_loop_termination() throws {
        // ensure a bad file terminates the loop
        let requestFile = try path(fixture: "loop-error.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["--loop", "2"])
        XCTAssertEqual(status, 1)
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_loop_duration() throws {
        let requestFile = try path(example: "basic.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["-l", "0.5", "-d", "1.5"])
        XCTAssertEqual(status, 0)
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_stats() throws {
        let requestFile = try path(example: "basic2.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["--stats"])
        XCTAssertEqual(status, 0)
        assertSnapshot(matching: output, as: .description)
    }
    
    func test_launch_set_up() throws {
        let requestFile = try path(example: "set_up.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["-l", "0.5", "-d", "1.0"])
        XCTAssertEqual(status, 0)
        assertSnapshot(matching: output, as: .description)
    }

}
