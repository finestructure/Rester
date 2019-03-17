//
//  PathTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 14/03/2019.
//

import XCTest

class PathTests: XCTestCase {

    func test_mimeType() throws {
        let file = path(fixture: "test.jpg")!
        XCTAssertEqual(file.mimeType, "image/jpeg")
    }

}
