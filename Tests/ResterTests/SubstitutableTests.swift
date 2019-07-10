//
//  GlobalTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 31/01/2019.
//

@testable import ResterCore
import XCTest
import Yams


class SubstitutableTests: XCTestCase {

    func test_substitute() throws {
        let vars: [Key: Value] = ["API_URL": .string("https://foo.bar"), "foo": .int(5)]
        let sub = try substitute(string: "${API_URL}/baz/${foo}/${foo}", with: vars)
        XCTAssertEqual(sub, "https://foo.bar/baz/5/5")
    }

    func test_Request() throws {
        let yml = """
            url: https://httpbin.org/anything
            variables:
              foo: ${var.foo}
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: yml)
        let r = Request(name: "r1", details: d)
        do {
            let sub = try r.substitute(variables: ["var": ["foo": "bar"]])
            XCTAssertEqual(sub.variables, ["foo": "bar"])
        }
    }

    func test_Body() throws {
        let vars: [Key: Value] = ["a": "1", "b": 2]
        let values: [Key: Value] = ["data": "values: ${a} ${b}"]

        XCTAssertEqual(try Body.json(values).substitute(variables: vars).json, ["data": "values: 1 2"])
        XCTAssertEqual(try Body.form(values).substitute(variables: vars).form, ["data": "values: 1 2"])
        XCTAssertEqual(try Body.multipart(values).substitute(variables: vars).multipart, ["data": "values: 1 2"])
        XCTAssertEqual(try Body.text("${a} ${b}").substitute(variables: vars).text, "1 2")
        XCTAssertEqual(try Body.file("${a} ${b}").substitute(variables: vars).file, "1 2")
    }


    func test_Operators_apply() throws {
        XCTAssertEqual(Operators.base64.apply(to: ".base64(foobar123)"), "Zm9vYmFyMTIz")
    }

    func test_substitute_with_Operator() throws {
        let vars: [Key: Value] = ["STRING": "foobar123"]
        let s = try substitute(string: ".base64(${STRING})", with: vars)
        XCTAssertEqual(s, "Zm9vYmFyMTIz")
    }

}
