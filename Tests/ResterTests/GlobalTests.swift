//
//  GlobalTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 31/01/2019.
//

import XCTest

@testable import ResterCore


class GlobalTests: XCTestCase {

    func test_subtitute() throws {
        let vars: [Key: Value] = ["API_URL": .string("https://foo.bar"), "foo": .int(5)]
        let sub = try substitute(string: "${API_URL}/baz/${foo}/${foo}", with: vars)
        XCTAssertEqual(sub, "https://foo.bar/baz/5/5")
    }

}
