// Generated using Sourcery 0.16.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import XCTest

@testable import ResterTests

// swiftlint:disable trailing_comma

extension Dictionary_extTests {
  static var allTests: [(String, (Dictionary_extTests) -> () throws -> Void)] = [
      ("test_processMutations_append", test_processMutations_append),
      ("test_processMutations_remove", test_processMutations_remove),
      ("test_processMutations_combined", test_processMutations_combined),
  ]
}
extension IssuesTests {
  static var allTests: [(String, (IssuesTests) -> () throws -> Void)] = [
      ("test_issue_39_referencing_into_empty_array", test_issue_39_referencing_into_empty_array),
  ]
}
extension MatcherTests {
  static var allTests: [(String, (MatcherTests) -> () throws -> Void)] = [
      ("test_decodable", test_decodable),
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
      ("test_parse_log", test_parse_log),
      ("test_parse_log_keypath", test_parse_log_keypath),
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
      ("test_request_execute_elapsed", test_request_execute_elapsed),
      ("test_execute_validateCertificate", test_execute_validateCertificate),
      ("test_parse_variables", test_parse_variables),
      ("test_variable_definition", test_variable_definition),
      ("test_variable_definition_append", test_variable_definition_append),
      ("test_variable_definition_remove", test_variable_definition_remove),
      ("test_parse_if", test_parse_if),
  ]
}
extension RequestValidationTests {
  static var allTests: [(String, (RequestValidationTests) -> () throws -> Void)] = [
      ("test_validate_status", test_validate_status),
      ("test_validate_json", test_validate_json),
      ("test_validate_json_regex", test_validate_json_regex),
  ]
}
extension ResponseTests {
  static var allTests: [(String, (ResponseTests) -> () throws -> Void)] = [
      ("test_merge", test_merge),
      ("test_merge_json_nil", test_merge_json_nil),
      ("test_merge_json_array", test_merge_json_array),
      ("test_merge_no_variables_json_array", test_merge_no_variables_json_array),
      ("test_merge_append_variable", test_merge_append_variable),
      ("test_merge_remove_variable", test_merge_remove_variable),
  ]
}
extension ResterTests {
  static var allTests: [(String, (ResterTests) -> () throws -> Void)] = [
      ("test_aggregate_variables", test_aggregate_variables),
      ("test_aggregate_requests", test_aggregate_requests),
      ("test_init", test_init),
      ("test_basic", test_basic),
      ("test_substitute_env", test_substitute_env),
      ("test_response_array_validation", test_response_array_validation),
      ("test_response_variable_legacy", test_response_variable_legacy),
      ("test_response_variable", test_response_variable),
      ("test_delay_env_var_substitution", test_delay_env_var_substitution),
      ("test_timeout_error", test_timeout_error),
      ("test_set_up", test_set_up),
      ("test_mode_random", test_mode_random),
      ("test_request_variable_definition_pick_up", test_request_variable_definition_pick_up),
      ("test_request_variable_append", test_request_variable_append),
      ("test_request_variable_remove", test_request_variable_remove),
  ]
}
extension RestfileTests {
  static var allTests: [(String, (RestfileTests) -> () throws -> Void)] = [
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
      ("test_parse_mode", test_parse_mode),
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
      ("test_Request", test_Request),
      ("test_Body", test_Body),
  ]
}
extension TestUtilsTests {
  static var allTests: [(String, (TestUtilsTests) -> () throws -> Void)] = [
      ("test_path", test_path),
      ("test_maskTime", test_maskTime),
      ("test_maskPath", test_maskPath),
      ("test_maskLine", test_maskLine),
      ("test_examplesDataDir", test_examplesDataDir),
      ("test_RNG", test_RNG),
  ]
}
extension UtilsTests {
  static var allTests: [(String, (UtilsTests) -> () throws -> Void)] = [
      ("test_format", test_format),
      ("test_iterationParameters", test_iterationParameters),
      ("test_loopParameters", test_loopParameters),
      ("test_Iteration_incremented_done", test_Iteration_incremented_done),
  ]
}
extension ValidationTests {
  static var allTests: [(String, (ValidationTests) -> () throws -> Void)] = [
      ("test_convertMatcher", test_convertMatcher),
      ("test_decode", test_decode),
      ("test_decode_key_typo", test_decode_key_typo),
      ("test_validate", test_validate),
      ("test_validate_regex", test_validate_regex),
      ("test_decode_json_array", test_decode_json_array),
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
      ("test_isJSONReference", test_isJSONReference),
      ("test_appendValue", test_appendValue),
      ("test_removeValue", test_removeValue),
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
      ("test_launch_no_requests", test_launch_no_requests),
      ("test_launch_no_restfiles", test_launch_no_restfiles),
      ("test_launch_binary_loop_termination", test_launch_binary_loop_termination),
      ("test_launch_loop_count", test_launch_loop_count),
      ("test_launch_stats", test_launch_stats),
      ("test_launch_set_up", test_launch_set_up),
      ("test_launch_binary_help", test_launch_binary_help),
  ]
}

XCTMain([
  testCase(Dictionary_extTests.allTests),
  testCase(IssuesTests.allTests),
  testCase(MatcherTests.allTests),
  testCase(ParameterTests.allTests),
  testCase(PathTests.allTests),
  testCase(RequestLoggingTests.allTests),
  testCase(RequestTests.allTests),
  testCase(RequestValidationTests.allTests),
  testCase(ResponseTests.allTests),
  testCase(ResterTests.allTests),
  testCase(RestfileTests.allTests),
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
