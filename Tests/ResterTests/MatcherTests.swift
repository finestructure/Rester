//
//  MatcherTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 16/04/2019.
//

@testable import ResterCore
import XCTest
import Yams


class MatcherTests: XCTestCase {

    func test_decodable() throws {
        let s = """
           eq: 5
           regex: .regex(.*)
           contains:
             foo: bar
        """
        struct Test: Decodable {
            let eq: Matcher
            let regex: Matcher
            let contains: Matcher
        }
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.eq, .equals(5))
        XCTAssertEqual(t.regex, .regex(".*".r!))
        XCTAssertEqual(t.contains, .contains(["foo": .equals("bar")]))
    }

}
