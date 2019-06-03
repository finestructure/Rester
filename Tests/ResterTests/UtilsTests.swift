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

    func test_iterationParameters() {
        XCTAssertEqual(iterationParameters(count: 1, duration: nil), .times(1))
        XCTAssert(iterationParameters(count: nil, duration: 2)?.isUntil ?? false)
        // count wins if both are set
        XCTAssertEqual(iterationParameters(count: 1, duration: 2), .times(1))
        XCTAssertNil(iterationParameters(count: nil, duration: nil))
    }

    func test_loopParameters() {
        do { // iteration nil, loop nil
            XCTAssertNil(loopParameters(count: nil, duration: nil, loop: nil))
        }
        do { // iteraion nil, loop non-nil
            let p = loopParameters(count: nil, duration: nil, loop: 1)
            XCTAssertEqual(p?.iteration, .forever)
            XCTAssertEqual(p?.delay, 1)
        }
        do { // iteration non-nil, loop nil
            let p = loopParameters(count: 1, duration: nil, loop: nil)
            XCTAssertEqual(p?.iteration, .times(1))
            XCTAssertEqual(p?.delay, 0)
        }
        do { // iteration non-nil, loop non-nil
            let p = loopParameters(count: 1, duration: nil, loop: 1)
            XCTAssertEqual(p?.iteration, .times(1))
            XCTAssertEqual(p?.delay, 1)
        }
    }

    func test_Iteration_incremented_done() {
        do { // .forever
            var i = Iteration.forever
            for _ in 0..<10 {
                XCTAssert(!i.done)
                i = i.incremented
            }
        }
        do { // .until
            let i1 = Iteration(seconds: 1)
            XCTAssert(!i1.done)
            XCTAssert(!i1.incremented.done)
            let i2 = Iteration(seconds: -1)
            XCTAssert(i2.done)
            XCTAssert(i2.incremented.done)
        }
        do {
            var i = Iteration.times(3)
            var count = 0
            for _ in 0..<10 {
                if i.done {
                    break
                } else {
                    count += 1
                }
                i = i.incremented
            }
            XCTAssertEqual(count, 3)
        }
    }
}


extension Iteration {
    var isUntil: Bool {
        switch self {
        case .until:
            return true
        default:
            return false
        }
    }
}
