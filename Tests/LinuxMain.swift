// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import XCTest

@testable import ResterTests

// swiftlint:disable trailing_comma
extension ResterTests {
  static var allTests: [(String, (ResterTests) -> () throws -> Void)] = [
      ("test_decode_variables", test_decode_variables),
      ("test_subtitute", test_subtitute),
      ("test_basic_request", test_basic_request),
      ("test_parse_validation", test_parse_validation),
      ("test_request_execute", test_request_execute),
      ("test_validate_status", test_validate_status),
      ("test_validate_json", test_validate_json),
      ("test_validate_json_regex", test_validate_json_regex),
      ("test_request_order", test_request_order),
      ("test_launch_binary", test_launch_binary),
  ]
}

XCTMain([
  testCase(ResterTests.allTests),
])
// swiftlint:enable trailing_comma
