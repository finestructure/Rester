// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import XCTest

@testable import ResterTests

// swiftlint:disable trailing_comma
extension RequestTests {
  static var allTests: [(String, (RequestTests) -> () throws -> Void)] = [
      ("test_parse_headers", test_parse_headers),
      ("test_request_execute_with_headers", test_request_execute_with_headers),
      ("test_parse_query", test_parse_query),
      ("test_request_execute_with_query", test_request_execute_with_query),
  ]
}
extension RestfileDecodingTests {
  static var allTests: [(String, (RestfileDecodingTests) -> () throws -> Void)] = [
      ("test_decode_variables", test_decode_variables),
      ("test_parse_basic", test_parse_basic),
      ("test_parse_body_json", test_parse_body_json),
      ("test_parse_body_form", test_parse_body_form),
      ("test_Restfile_init", test_Restfile_init),
      ("test_parse_restfiles_basic", test_parse_restfiles_basic),
      ("test_parse_restfiles_invalid_path", test_parse_restfiles_invalid_path),
      ("test_parse_complex_form", test_parse_complex_form),
  ]
}
extension RestfileRequestTests {
  static var allTests: [(String, (RestfileRequestTests) -> () throws -> Void)] = [
      ("test_request_execute", test_request_execute),
      ("test_validate_status", test_validate_status),
      ("test_validate_json", test_validate_json),
      ("test_validate_json_regex", test_validate_json_regex),
      ("test_request_order", test_request_order),
      ("test_launch_binary", test_launch_binary),
      ("test_post_request_json", test_post_request_json),
      ("test_post_request_form", test_post_request_form),
      ("test_response_variable", test_response_variable),
      ("test_validate_json_array", test_validate_json_array),
  ]
}
extension SubstitutableTests {
  static var allTests: [(String, (SubstitutableTests) -> () throws -> Void)] = [
      ("test_substitute", test_substitute),
      ("test_substitute_Body", test_substitute_Body),
  ]
}
extension ValidationTests {
  static var allTests: [(String, (ValidationTests) -> () throws -> Void)] = [
      ("test_convertMatcher", test_convertMatcher),
      ("test_parse_Validation", test_parse_Validation),
      ("test_validate", test_validate),
      ("test_parse_json_array", test_parse_json_array),
      ("test_validate_json_array", test_validate_json_array),
  ]
}
extension ValueTests {
  static var allTests: [(String, (ValueTests) -> () throws -> Void)] = [
      ("test_decodeBasicTypes", test_decodeBasicTypes),
      ("test_encodeBasicTypes", test_encodeBasicTypes),
      ("test_null_json", test_null_json),
      ("test_encode_null", test_encode_null),
      ("test_bool_json", test_bool_json),
      ("test_decodeComplexResponse", test_decodeComplexResponse),
      ("test_formUrlEncoded", test_formUrlEncoded),
  ]
}

XCTMain([
  testCase(RequestTests.allTests),
  testCase(RestfileDecodingTests.allTests),
  testCase(RestfileRequestTests.allTests),
  testCase(SubstitutableTests.allTests),
  testCase(ValidationTests.allTests),
  testCase(ValueTests.allTests),
])
// swiftlint:enable trailing_comma
