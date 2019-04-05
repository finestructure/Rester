//
//  ExampleTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 17/03/2019.
//

import Path
import ResterCore
import SnapshotTesting
import XCTest


class ExampleTests: SnapshotTestCase {

    func test_examples() throws {
        for file in try examplesDirectory().unwrapped().ls().files(withExtension: "yml") {
            let (status, output) = try launch(with: file)
            let name = file.basename(dropExtension: true)

            switch name {
            case "delay", "error":
                // these tests are intended to show errors - so they are expected to fail
                XCTAssert(status == 1, "exit status not 0, was: \(status), output: \(output)")
            case "github" where Current.environment["GITHUB_TOKEN"] == nil:
                print("⚠️ Skipping test_examples for 'github' because GITHUB_TOKEN is not set")
                continue
            default:
                XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
            }

            assertSnapshot(matching: output, as: .description, named: name)
        }
    }

}
