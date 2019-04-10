//
//  ExampleTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 17/03/2019.
//

import Path
import Regex
import ResterCore
import SnapshotTesting
import XCTest


class ExampleTests: SnapshotTestCase {

    func test_examples() throws {
        // Test all examples except special treatment ones, which have their own tests
        let special = ["github.yml", "delay.yml", "error.yml"]
        let files = try examplesDirectory().unwrapped().ls().files(withExtension: "yml")
            .filter { !special.contains($0.basename()) }
        for file in files {
            let name = file.basename(dropExtension: true)
            let (status, output) = try launch(with: file)
            XCTAssertEqual(status, 0)
            assertSnapshot(matching: output, as: .description, named: name)
        }
    }

    func test_error_example() throws {
        let file = path(example: "error.yml")!
        let name = file.basename(dropExtension: true)
        let (status, output) = try launch(with: file)
        // expected to fail
        XCTAssertEqual(status, 1)
        assertSnapshot(matching: output, as: .description, named: name, testName: "test_examples")
    }

    func test_delay_example() throws {
        let file = path(example: "delay.yml")!
        let name = file.basename(dropExtension: true)
        let (status, output) = try launch(with: file, extraArguments: ["-t", "1"])
        // expected to fail
        XCTAssertEqual(status, 1)
        assertSnapshot(matching: output, as: .description, named: name, testName: "test_examples")
    }

    func test_github_example() throws {
        guard Current.environment["GITHUB_TOKEN"] != nil else {
            print("⚠️ Skipping test_examples for 'github' because GITHUB_TOKEN is not set")
            return
        }

        let file = path(example: "github.yml")!
        let name = file.basename(dropExtension: true)

        // Un-comment GITHUB_TOKEN header
        // We keep it disabled in the examples so users can test run the script
        // but for CI tests we need to run it with the token enabled to avoid
        // rate limiting errors.
        let content = try String(contentsOf: file)
        let pattern = try! Regex(pattern: #"# Authorization: token \$\{GITHUB_TOKEN\}"#)
        let modified = pattern.replaceAll(in: content, with: "Authorization: token ${GITHUB_TOKEN}")

        try withTempDir { tmp in
            // Write tempfile with GITHUB_TOKEN header enabled
            let tempfile = tmp/"github.yml"
            try modified.write(to: tempfile)

            let (status, output) = try launch(with: tempfile)

            XCTAssertEqual(status, 0)
            assertSnapshot(matching: output, as: .description, named: name, testName: "test_examples")
        }
    }

}
