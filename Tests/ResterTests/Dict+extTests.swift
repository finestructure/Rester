//
//  Dict+extTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 16/04/2019.
//

@testable import ResterCore
import XCTest


class Dict_extTests: XCTestCase {

    func test_append() throws {
        do {
            let global: [Key: Value] = ["docs": .array([])]
            let vars: [Key: Value] = ["docs": ".append(foo)"]
            XCTAssertEqual(global.append(variables: vars), ["docs": .array(["foo"])])
        }
        do {
            let global: [Key: Value] = ["docs": .array([])]
            let values: Value = .dictionary(["docs": ".append(foo)"])
            XCTAssertEqual(global.append(values: values), ["docs": .array(["foo"])])
        }
    }

}
