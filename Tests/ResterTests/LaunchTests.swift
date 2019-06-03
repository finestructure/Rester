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

    func test_launch_no_requests() throws {
        // TODO: improve this error message
        let requestFile = try path(fixture: "no-requests.yml").unwrapped()
        let (status, output) = try launch(with: requestFile)
        XCTAssertEqual(status, 1)
        // macOS and Linux have slightly different error messages
        #if os(macOS)
            assertSnapshot(matching: output, as: .description)
        #endif
    }

    func test_launch_no_restfiles() throws {
        let requestFile = try path(fixture: "no-restfiles.yml").unwrapped()
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

    func test_launch_loop_count() throws {
        let requestFile = try path(example: "basic.yml").unwrapped()
        let (status, output) = try launch(with: requestFile, extraArguments: ["-c", "3", "-d", "0"])
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
        let (status, output) = try launch(with: requestFile, extraArguments: ["-c", "2"])
        XCTAssertEqual(status, 0)
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_help() throws {
        let (status, output) = try launch(arguments: ["--help"])
        XCTAssertEqual(status, 1)
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_skipped() throws {
        let requestFile = try path(fixture: "skipped.yml").unwrapped()
        let (status, output) = try launch(with: requestFile)
        XCTAssertEqual(status, 0)
        assertSnapshot(matching: output, as: .description)
    }

}
