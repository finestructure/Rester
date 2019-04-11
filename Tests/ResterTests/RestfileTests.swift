import XCTest

import LegibleError
import Path
import PromiseKit
import Rainbow
import Yams
@testable import ResterCore


final class RestfileTests: XCTestCase {

    func test_request_order() throws {
        let s = """
            requests:
              first:
                url: http://foo.com
              second:
                url: http://foo.com
              3rd:
                url: http://foo.com
            """
        let rester = try YAMLDecoder().decode(Restfile.self, from: s)
        let names = rester.requests.map { $0.name }
        XCTAssertEqual(names, ["first", "second", "3rd"])
    }

}
