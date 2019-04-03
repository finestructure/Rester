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

            if name == "delay" {
                // the delay test is intended to show the timeout error - so it's expected to fail
                XCTAssert(status == 1, "exit status not 0, was: \(status), output: \(output)")
            } else if name == "github" && Current.environment["GITHUB_TOKEN"] == nil {
                print("⚠️ Skipping test_examples for 'github' because GITHUB_TOKEN is not set")
                continue
            } else {
                XCTAssert(status == 0, "exit status not 0, was: \(status), output: \(output)")
            }

            assertSnapshot(matching: output, as: .description, named: name)
        }
    }

}
