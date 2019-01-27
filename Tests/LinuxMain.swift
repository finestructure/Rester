// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import XCTest

@testable import ResterTests

// swiftlint:disable trailing_comma
extension ResterTests {
  static var allTests: [(String, (ResterTests) -> () throws -> Void)] = [
      ("test_decode_variables", test_decode_variables),
      ("test_subtitute", test_subtitute),
      ("test_parse_basic", test_parse_basic),
      ("test_parse_validation", test_parse_validation),
      ("test_parse_body", test_parse_body),
      ("test_request_execute", test_request_execute),
      ("test_validate_status", test_validate_status),
      ("test_validate_json", test_validate_json),
      ("test_validate_json_regex", test_validate_json_regex),
      ("test_request_order", test_request_order),
      ("test_launch_binary", test_launch_binary),
      ("test_post_request", test_post_request),
      ("test_anycodable_dict", test_anycodable_dict),
  ]
}
extension ValueTests {
  static var allTests: [(String, (ValueTests) -> () throws -> Void)] = [
      ("test_decodeBasicTypes", test_decodeBasicTypes),
      ("test_encodeBasicTypes", test_encodeBasicTypes),
  ]
}

XCTMain([
  testCase(ResterTests.allTests),
  testCase(ValueTests.allTests),
])
// swiftlint:enable trailing_comma
