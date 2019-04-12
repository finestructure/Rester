//
//  TestUtilsTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 17/03/2019.
//

import Gen
import Path
@testable import ResterCore
import XCTest


class TestUtilsTests: XCTestCase {

    func test_path() throws {
        XCTAssertEqual(path(fixture: "basic.yml")?.basename(), "basic.yml")
        XCTAssertEqual(path(example: "array")?.basename(), "array")
    }

    func test_maskTime() throws {
        XCTAssertEqual("basic PASSED (0.01s)".maskTime, "basic PASSED (X.XXXs)")
        // NB: not masking timings without at least 2+ decimal places
        XCTAssertEqual("basic PASSED (0s)".maskTime, "basic PASSED (0s)")
    }

    func test_maskPath() throws {
        do {  // file
            let filePath = path(fixture: "basic.yml")!
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

    func test_maskLine() throws {
        do {
            let input = "first line\nJSON: [\" ...\nnext line"
            let output = "first line\nJSON: <non-deterministic output masked>\nnext line"
            XCTAssertEqual(input.maskLine(prefix: "JSON: "), output)
        }
        do {  // test to preserve blank lines
            let input = "first line\n\nJSON: [\" ...\n\nnext line"
            let output = "first line\n\nJSON: <non-deterministic output masked>\n\nnext line"
            XCTAssertEqual(input.maskLine(prefix: "JSON: "), output)
        }
    }

    func test_examplesDataDir() throws {
        XCTAssertEqual(examplesDirectory()?.basename(), "examples")
        XCTAssert((examplesDirectory()!/"array.yml").exists)
    }

    func test_RNG() {
        // ensure we get stable random number so the other tests pass
        do {
            Current.rng = AnyRandomNumberGenerator(LCRNG(seed: 0))
            let g = Gen.int(in: 0...10)
            XCTAssertEqual(g.run(using: &Current.rng), 10)
            XCTAssertEqual(g.run(using: &Current.rng), 10)
            XCTAssertEqual(g.run(using: &Current.rng), 6)
            XCTAssertEqual(g.run(using: &Current.rng), 3)
            XCTAssertEqual(g.run(using: &Current.rng), 10)
        }
        do {
            Current.rng = AnyRandomNumberGenerator(LCRNG(seed: 0))
            let g = Gen.element(of: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
            XCTAssertEqual(g.run(using: &Current.rng), 4)
            XCTAssertEqual(g.run(using: &Current.rng), 9)
            XCTAssertEqual(g.run(using: &Current.rng), 4)
            XCTAssertEqual(g.run(using: &Current.rng), 5)
            XCTAssertEqual(g.run(using: &Current.rng), 6)
        }
    }

}
