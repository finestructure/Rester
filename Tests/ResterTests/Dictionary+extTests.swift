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
            XCTAssertEqual(global._append(variables: vars), ["docs": .array([1, "foo"])])
        }
    }

    func test_remove() throws {
        do {
            let global: [Key: Value] = ["docs": .array(["foo", 1])]
            let vars: [Key: Value] = ["docs": ".remove(foo)"]
            XCTAssertEqual(global._remove(variables: vars), ["docs": .array([1])])
        }
    }

    func test_processMutations() throws {
        do {  // test variables: [Key: Value] signature
            var global: [Key: Value] = ["docs1": .array(["foo", 1]), "docs2": .array([2])]
            global = global.processMutations(variables: ["docs1": ".remove(foo)", "docs2": ".append(b)"])
            XCTAssertEqual(global, ["docs1": .array([1]), "docs2": .array([2, "b"])])
            global = global.processMutations(variables: ["docs1": ".append(42)"])
            XCTAssertEqual(global, ["docs1": .array([1, "42"]), "docs2": .array([2, "b"])])
        }
        do {  // test values: Value? signature
            let global: [Key: Value] = ["docs1": .array(["foo", 1]), "docs2": .array([2])]
            XCTAssertEqual(
                global.processMutations(values: .dictionary(["docs1": ".remove(foo)", "docs2": ".append(b)"])),
                ["docs1": .array([1]), "docs2": .array([2, "b"])]
            )
        }
    }

}
