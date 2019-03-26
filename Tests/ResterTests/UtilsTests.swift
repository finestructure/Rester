//
//  UtilsTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 25/03/2019.
//

import XCTest
@testable import ResterCore


class UtilsTests: XCTestCase {

    func test_format() {
        XCTAssertEqual(format(TimeInterval(1.23456)), "1.235")
        XCTAssertEqual(format(TimeInterval(0.23456)), "0.235")
    }

}
