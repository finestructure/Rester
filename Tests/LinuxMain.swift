// Generated using Sourcery 0.16.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import XCTest

@testable import ResterTests

// swiftlint:disable trailing_comma

extension IssuesTests {
  static var allTests: [(String, (IssuesTests) -> () throws -> Void)] = [
      ("test_issue_39_referencing_into_empty_array", test_issue_39_referencing_into_empty_array),
  ]
}
extension ParameterTests {
  static var allTests: [(String, (ParameterTests) -> () throws -> Void)] = [
      ("test_multipartEncode_file", test_multipartEncode_file),
      ("test_multipartEncoded_file", test_multipartEncoded_file),
  ]
}
extension PathTests {
  static var allTests: [(String, (PathTests) -> () throws -> Void)] = [
      ("test_mimeType", test_mimeType),
  ]
}
extension RequestLoggingTests {
  static var allTests: [(String, (RequestLoggingTests) -> () throws -> Void)] = [
      ("test_log_request", test_log_request),
      ("test_log_request_json_keypath", test_log_request_json_keypath),
      ("test_log_request_file", test_log_request_file),
  ]
}
extension RequestTests {
  static var allTests: [(String, (RequestTests) -> () throws -> Void)] = [
      ("test_post_json", test_post_json),
      ("test_post_form", test_post_form),
      ("test_post_multipart", test_post_multipart),
      ("test_post_text", test_post_text),
      ("test_post_file", test_post_file),
      ("test_put_json", test_put_json),
      ("test_delete", test_delete),
      ("test_parse_headers", test_parse_headers),
      ("test_request_execute_with_headers", test_request_execute_with_headers),
      ("test_validate_headers", test_validate_headers),
      ("test_parse_query", test_parse_query),
      ("test_request_execute_with_query", test_request_execute_with_query),
      ("test_parse_delay", test_parse_delay),
      ("test_delay_substitution", test_delay_substitution),
      ("test_delay_execution", test_delay_execution),
      ("test_parse_log", test_parse_log),
      ("test_parse_log_keypath", test_parse_log_keypath),
      ("test_request_execute_elapsed", test_request_execute_elapsed),
      ("test_execute_validateCertificate", test_execute_validateCertificate),
  ]
}
extension RequestValidationTests {
  static var allTests: [(String, (RequestValidationTests) -> () throws -> Void)] = [
      ("test_validate_status", test_validate_status),
      ("test_validate_json", test_validate_json),
      ("test_validate_json_regex", test_validate_json_regex),
  ]
}
extension ResterTests {
  static var allTests: [(String, (ResterTests) -> () throws -> Void)] = [
      ("test_init", test_init),
      ("test_delay_env_var_substitution", test_delay_env_var_substitution),
  ]
}
extension RestfileDecodingTests {
  static var allTests: [(String, (RestfileDecodingTests) -> () throws -> Void)] = [
      ("test_decode_variables", test_decode_variables),
      ("test_parse_basic", test_parse_basic),
      ("test_parse_malformed_request", test_parse_malformed_request),
      ("test_parse_malformed_validation", test_parse_malformed_validation),
      ("test_parse_request_order", test_parse_request_order),
      ("test_parse_body_json", test_parse_body_json),
      ("test_parse_body_form", test_parse_body_form),
      ("test_parse_body_multipart", test_parse_body_multipart),
      ("test_parse_body_text", test_parse_body_text),
      ("test_parse_body_file", test_parse_body_file),
      ("test_Restfile_init", test_Restfile_init),
      ("test_parse_restfiles_basic", test_parse_restfiles_basic),
      ("test_parse_restfiles_invalid_path", test_parse_restfiles_invalid_path),
      ("test_parse_complex_form", test_parse_complex_form),
      ("test_parse_set_up", test_parse_set_up),
  ]
}
extension RestfileExecutionTests {
  static var allTests: [(String, (RestfileExecutionTests) -> () throws -> Void)] = [
      ("test_expandedRequest", test_expandedRequest),
      ("test_request_order", test_request_order),
      ("test_substitute_env", test_substitute_env),
      ("test_response_array_validation", test_response_array_validation),
      ("test_response_variable_legacy", test_response_variable_legacy),
      ("test_response_variable", test_response_variable),
      ("test_timeout_error", test_timeout_error),
  ]
}
extension StatsTests {
  static var allTests: [(String, (StatsTests) -> () throws -> Void)] = [
      ("test_average", test_average),
      ("test_median", test_median),
      ("test_percentile", test_percentile),
      ("test_stddev", test_stddev),
  ]
}
extension SubstitutableTests {
  static var allTests: [(String, (SubstitutableTests) -> () throws -> Void)] = [
      ("test_substitute", test_substitute),
      ("test_substitute_Body", test_substitute_Body),
  ]
}
extension TestUtilsTests {
  static var allTests: [(String, (TestUtilsTests) -> () throws -> Void)] = [
      ("test_path", test_path),
      ("test_maskTime", test_maskTime),
      ("test_maskPath", test_maskPath),
      ("test_maskLine", test_maskLine),
      ("test_examplesDataDir", test_examplesDataDir),
  ]
}
extension UtilsTests {
  static var allTests: [(String, (UtilsTests) -> () throws -> Void)] = [
      ("test_format", test_format),
  ]
}
extension ValidationTests {
  static var allTests: [(String, (ValidationTests) -> () throws -> Void)] = [
      ("test_convertMatcher", test_convertMatcher),
      ("test_parse_Validation", test_parse_Validation),
      ("test_validate", test_validate),
      ("test_validate_regex", test_validate_regex),
      ("test_parse_json_array", test_parse_json_array),
      ("test_validate_json_array", test_validate_json_array),
      ("test_Matcher_substitute", test_Matcher_substitute),
      ("test_Validation_substitute", test_Validation_substitute),
  ]
}
extension ValueTests {
  static var allTests: [(String, (ValueTests) -> () throws -> Void)] = [
      ("test_formUrlEncoded", test_formUrlEncoded),
      ("test_multipartEncoded", test_multipartEncoded),
      ("test_key_substitution", test_key_substitution),
      ("test_path", test_path),
  ]
}

extension ExampleTests {
  static var allTests: [(String, (ExampleTests) -> () throws -> Void)] = [
      ("test_examples", test_examples),
      ("test_error_example", test_error_example),
      ("test_delay_example", test_delay_example),
      ("test_github_example", test_github_example),
  ]
}
extension LaunchTests {
  static var allTests: [(String, (LaunchTests) -> () throws -> Void)] = [
      ("test_launch_binary", test_launch_binary),
      ("test_launch_binary_verbose", test_launch_binary_verbose),
      ("test_launch_binary_malformed", test_launch_binary_malformed),
      ("test_launch_binary_loop_termination", test_launch_binary_loop_termination),
      ("test_launch_loop_duration", test_launch_loop_duration),
      ("test_launch_stats", test_launch_stats),
  ]
}

XCTMain([
  testCase(IssuesTests.allTests),
  testCase(ParameterTests.allTests),
  testCase(PathTests.allTests),
  testCase(RequestLoggingTests.allTests),
  testCase(RequestTests.allTests),
  testCase(RequestValidationTests.allTests),
  testCase(ResterTests.allTests),
  testCase(RestfileDecodingTests.allTests),
  testCase(RestfileExecutionTests.allTests),
  testCase(StatsTests.allTests),
  testCase(SubstitutableTests.allTests),
  testCase(TestUtilsTests.allTests),
  testCase(UtilsTests.allTests),
  testCase(ValidationTests.allTests),
  testCase(ValueTests.allTests),
  testCase(ExampleTests.allTests),
  testCase(LaunchTests.allTests),
])

// swiftlint:enable trailing_comma
