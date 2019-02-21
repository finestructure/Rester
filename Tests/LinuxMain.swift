// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import XCTest

@testable import ResterTests

// swiftlint:disable trailing_comma
extension LaunchTests {
  static var allTests: [(String, (LaunchTests) -> () throws -> Void)] = [
      ("test_launch_binary", test_launch_binary),
  ]
}
extension RequestExecutionTests {
  static var allTests: [(String, (RequestExecutionTests) -> () throws -> Void)] = [
      ("test_request_execute", test_request_execute),
      ("test_validate_status", test_validate_status),
      ("test_validate_json", test_validate_json),
      ("test_validate_json_regex", test_validate_json_regex),
      ("test_request_order", test_request_order),
      ("test_post_request_json", test_post_request_json),
      ("test_post_request_form", test_post_request_form),
      ("test_substitute_env", test_substitute_env),
      ("test_put_request_json", test_put_request_json),
      ("test_validate_headers", test_validate_headers),
      ("test_delete_request", test_delete_request),
      ("test_delay_request", test_delay_request),
      ("test_delay_request_substitution", test_delay_request_substitution),
      ("test_log_request", test_log_request),
      ("test_log_request_json_keypath", test_log_request_json_keypath),
  ]
}
extension RequestTests {
  static var allTests: [(String, (RequestTests) -> () throws -> Void)] = [
      ("test_parse_headers", test_parse_headers),
      ("test_request_execute_with_headers", test_request_execute_with_headers),
      ("test_parse_query", test_parse_query),
      ("test_request_execute_with_query", test_request_execute_with_query),
      ("test_parse_delay", test_parse_delay),
      ("test_delay_substitution", test_delay_substitution),
      ("test_parse_log", test_parse_log),
      ("test_parse_log_keypath", test_parse_log_keypath),
  ]
}
extension ResterTests {
  static var allTests: [(String, (ResterTests) -> () throws -> Void)] = [
      ("test_init", test_init),
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
      ("test_Matcher_substitute", test_Matcher_substitute),
      ("test_Validation_substitute", test_Validation_substitute),
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
      ("test_key_lookup", test_key_lookup),
      ("test_key_lookup_nested", test_key_lookup_nested),
      ("test_key_substitution", test_key_substitution),
  ]
}

XCTMain([
  testCase(LaunchTests.allTests),
  testCase(RequestExecutionTests.allTests),
  testCase(RequestTests.allTests),
  testCase(ResterTests.allTests),
  testCase(RestfileDecodingTests.allTests),
  testCase(SubstitutableTests.allTests),
  testCase(ValidationTests.allTests),
  testCase(ValueTests.allTests),
])
// swiftlint:enable trailing_comma
