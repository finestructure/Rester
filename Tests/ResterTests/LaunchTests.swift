//
//  LaunchTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 19/02/2019.
//

import XCTest
import SnapshotTesting


@testable import ResterCore


class LaunchTests: SnapshotTestCase {

    func test_launch_binary() throws {
        let requestFile = path(fixture: "basic.yml")!
        let (status, output) = try launch(with: requestFile)

        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_verbose() throws {
        let requestFile = path(fixture: "basic.yml")!
        let (status, output) = try launch(with: requestFile, extraArguments: ["-v", "-t", "7"])

        XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

    func test_launch_binary_malformed() throws {
        let requestFile = path(fixture: "malformed.yml")!
        let (status, output) = try launch(with: requestFile)

        XCTAssert(status == 1, "exit status not 1, was: \(status), output: \(output)")
        assertSnapshot(matching: output, as: .description)
    }

}
