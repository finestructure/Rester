//
//  ParameterTests.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 14/03/2019.
//

import XCTest
@testable import ResterCore


let testJPG = """
\(MultipartBoundary)
Content-Disposition: form-data; name="file"; filename="test.jpg"
Content-Type: image/jpeg

dummy data
"""


class ParameterTests: XCTestCase {

    func test_multipartEncode_file() throws {
        let file = path(for: "test.jpg")!
        XCTAssertEqual(
            String(data: try multipartEncode(file: file), encoding: .utf8),
            testJPG
        )
    }

    func test_multipartEncoded_file() throws {
        // tests multipart encoding of "file" parameters
        Current.workDir = testDataDirectory()!
        let p = Parameter(key: "file", value: ".file(test.jpg)")!
        XCTAssertEqual(
            String(data: try p.multipartEncoded(), encoding: .utf8),
            testJPG
        )
    }

}
