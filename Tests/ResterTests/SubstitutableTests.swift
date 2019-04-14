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
              foo: ${json.method}
            """
        let d = try YAMLDecoder().decode(Request.Details.self, from: yml)
        let r = Request(name: "r1", details: d)
        do {
            let sub = try r.substitute(variables: ["json": ["method": "GET"]])
            XCTAssertEqual(sub.variables, ["foo": "GET"])
        }
//        do {
//            // Also accept r1.foo for substitution. This is how the request's
//            // response values will come back from substitution at the request
//            // level.
//            let sub = try r.substitute(variables: ["r1": ["method": "GET"]])
//            XCTAssertEqual(sub.variables, ["foo": "GET"])
//        }
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

}
