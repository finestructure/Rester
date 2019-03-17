//
//  TestUtilsTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 17/03/2019.
//

import XCTest

class TestUtilsTests: XCTestCase {

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

}
