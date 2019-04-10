//
//  StatsTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 10/04/2019.
//

import XCTest
@testable import ResterCore


class StatsTests: XCTestCase {

    func test_average() {
        XCTAssertEqual([1.0, 4.0, 3.0, 2.0].average, 2.5)
        XCTAssertEqual([1, 4, 3, 2].average, 2.5)
        XCTAssert([Double]().average.isNaN)
    }

    func test_median() {
        XCTAssertEqual([24, 1, 4, 5, 20, 6, 7, 12, 14, 18, 19, 22].median, 13.0)
        XCTAssertEqual([1.0, 5.0, 3.0, 2.0].median, 2.5)
        XCTAssertEqual([1].median, 1.0)
        XCTAssert([Double]().median.isNaN)
    }

    func test_percentile() {
        let values: [Double] = [43, 54, 56, 61, 62, 66, 68, 69, 69, 70, 71, 72, 77, 78, 79, 85, 87, 88, 89, 93, 95, 96, 98, 99, 99].shuffled()
        XCTAssertEqual(values.percentile(0.9), 98.0)
        XCTAssertEqual(values.percentile(1.0), 99.0)
        XCTAssertEqual(values.percentile(1.1), 99.0)
        XCTAssertEqual(values.percentile(0.5), values.median)
        XCTAssertEqual([1, 4, -3, 2, -9, -7, 0, -4, -1, 2, 1, -5, -3, 10, 10, 5].percentile(0.75), 3)
        XCTAssert([0, 1].percentile(0).isNaN)
        XCTAssert([1].percentile(0.5).isNaN)
        XCTAssert([1].percentile(1.0).isNaN)
        XCTAssert([1].percentile(0).isNaN)
        XCTAssert([Double]().percentile(0).isNaN)
    }

    func test_stddev() {
        let values: [Double] = [10, 8, 10, 8, 8 , 4]
        XCTAssertEqual(values.stddev, 2.19, accuracy: 0.01)
    }
}
