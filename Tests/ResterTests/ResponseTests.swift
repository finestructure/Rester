//
//  ResponseTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 15/04/2019.
//

@testable import ResterCore
import XCTest


class ResponseTests: XCTestCase {

    func test_merge() throws {
        let vars: [Key: Value] = ["foo": "json.method"]
        let json: Value? = ["method": "GET"]
        XCTAssertEqual(try merge(variables: vars, json: json), ["method": "GET", "foo": "GET"])
    }

    func test_merge_json_nil() throws {
        let vars: [Key: Value] = ["foo": "json.method"]
        let json: Value? = nil
        XCTAssertEqual(try merge(variables: vars, json: json), ["foo": "json.method"])
    }

    func test_merge_json_array() throws {
        let vars: [Key: Value] = ["foo": "json.method"]
        let json: Value? = .array([])
        XCTAssertThrowsError(try merge(variables: vars, json: json)) { error in
            XCTAssertEqual(error.legibleLocalizedDescription, "internal error: Cannot merge variables unless response is a JSON object")
        }
    }

    func test_merge_no_variables_json_array() throws {
        let vars: [Key: Value] = [:]
        let json: Value? = .array([1, "2", 3])
        XCTAssertEqual(try merge(variables: vars, json: json), json)
    }

}
