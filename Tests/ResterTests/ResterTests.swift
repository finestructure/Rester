import XCTest
import Yams
@testable import ResterCore


final class ResterTests: XCTestCase {

    func test_variables() throws {
        let s = try readFixture("env.yml")
        let env = try YAMLDecoder().decode(Rester.self, from: s)
        XCTAssertEqual(env.variables!["INT_VALUE"], .int(42))
    }

}


func url(for fixture: String, path: String = #file) -> URL {
  let testDir = URL(fileURLWithPath: path).deletingLastPathComponent()
  return testDir.appendingPathComponent("TestData/\(fixture)")
}


func readFixture(_ fixture: String, path: String = #file) throws -> String {
  let file = url(for: fixture)
  return try String(contentsOf: file)
}
