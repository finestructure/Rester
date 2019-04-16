//
//  ValidationTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 27/01/2019.
//

import XCTest
@testable import ResterCore

import Regex
import Yams


extension Matcher {
    var contains: [Key: Matcher]? {
        switch self {
        case .contains(let dict):
            return dict
        default:
            return nil
        }
    }
}


class ValidationTests: XCTestCase {

    func test_decode() throws {
        struct Test: Decodable {
            let validation: Validation
        }
        let s = """
        validation:
          status: 200
          json:
            int: 42
            string: foo
            regex: .regex(.*)
            object:
              foo: bar
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.status, .equals(.int(200)))
        let containing = t.validation.json?.contains
        XCTAssertNotNil(containing)
        XCTAssertEqual(containing?["int"], .equals(.int(42)))
        XCTAssertEqual(containing?["string"], .equals(.string("foo")))
        XCTAssertEqual(containing?["regex"], .regex(".*".r!))
        XCTAssertEqual(containing?["object"], .contains(["foo": .equals("bar")]))
    }

    func test_decode_key_typo() throws {
        // We want to be sure to raise when there are typos in `validation:`
        struct Test: Decodable {
            let validation: Validation
        }
        let s = """
        validation:
          states: 200
          json:
            int: 42
        """
        XCTAssertThrowsError(try YAMLDecoder().decode(Test.self, from: s)) { error in
            XCTAssert(error.legibleLocalizedDescription.contains(#"unexpectedKeyFound("states")"#),
                      "was: \(error.legibleLocalizedDescription)")
        }
    }

    func test_decode_json_array() throws {
        struct Test: Decodable {
            let validation: Validation
        }
        let s = """
        validation:
          status: 200
          json:
            0:
              foo: bar
            1: value1
            -1: 42
        """
        let t = try YAMLDecoder().decode(Test.self, from: s)
        XCTAssertEqual(t.validation.json,
                       .contains([
                        "0": .contains(["foo": .equals("bar")]),
                        "1": .equals("value1"),
                        "-1": .equals(42)
                        ])
        )
    }

    func test_Validation_substitute() throws {
        let validation = Validation(status: nil, headers: nil, json: .contains(["data": .equals("${test}")]))

        XCTAssertEqual(validation.json,
                       .contains(["data": .equals("${test}")]))

        let vars: [Key: Value] = ["test": "resolved"]
        let resolved = try validation.substitute(variables: vars)
        XCTAssertEqual(resolved.json,
                       .contains(["data": .equals("resolved")]))
    }

}
