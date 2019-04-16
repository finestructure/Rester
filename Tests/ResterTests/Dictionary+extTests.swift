//
//  Dict+extTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 16/04/2019.
//

@testable import ResterCore
import XCTest


class Dictionary_extTests: XCTestCase {

    func test_append() throws {
        do {
            let global: [Key: Value] = ["docs": .array([1])]
            let vars: [Key: Value] = ["docs": ".append(foo)"]
            XCTAssertEqual(global.append(variables: vars), ["docs": .array([1, "foo"])])
        }
        do {
            let global: [Key: Value] = ["docs": .array([1])]
            let values: Value = .dictionary(["docs": ".append(foo)"])
            XCTAssertEqual(global.append(values: values), ["docs": .array([1, "foo"])])
        }
    }

    func test_remove() throws {
        do {
            let global: [Key: Value] = ["docs": .array(["foo", 1])]
            let vars: [Key: Value] = ["docs": ".remove(foo)"]
            XCTAssertEqual(global.remove(variables: vars), ["docs": .array([1])])
        }
        do {
            let global: [Key: Value] = ["docs": .array(["foo", 1])]
            let values: Value = .dictionary(["docs": ".remove(foo)"])
            XCTAssertEqual(global.remove(values: values), ["docs": .array([1])])
        }
    }

}
