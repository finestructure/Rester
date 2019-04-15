//
//  Response.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 01/02/2019.
//

import Foundation


public struct Response: Equatable {
    public let elapsed: TimeInterval
    let data: Data
    let response: HTTPURLResponse
    let json: Value?
    let variables: Value?

    init(elapsed: TimeInterval, data: Data, response: URLResponse, variables: [Key: Value]) throws {
        self.elapsed = elapsed
        self.data = data
        guard let resp = response as? HTTPURLResponse else {
            throw ResterError.internalError("Failed to convert \(response) to HTTPURLResponse")
        }
        self.response = resp
        self.json = data.json
        self.variables = try merge(variables: variables, json: json)
    }

    var status: Int {
        return response.statusCode
    }

    var headers: [Key: Value] {
        let headers = response.allHeaderFields
        let res: [(String, Value)] = headers.compactMap {
            guard
                let key = $0.key as? String,
                let value = $0.value as? String
                else { return nil }
            return (key, Value.string(value))
        }
        return Dictionary(uniqueKeysWithValues: res)
    }

}


extension Response: CustomStringConvertible {
    public var description: String {
        return """
        Status:   \(response.statusCode)
        Headers:  \(response.allHeaderFields)
        Data:     \(data.count) bytes
        """
    }
}



/// Attempts to merge request variables with the request response values. As part of
/// this it also resolves references to response values, like `json.value` that are
/// being referenced in the variables.
///
/// - Parameters:
///   - variables: Variables defined in the `variables:` section of a request
///   - json: JSON response of the request
/// - Returns: Value containing the merged variables and JSON response
/// - Throws: If variables are defined but the response is not a JSON object they
///   cannot be merged into the reponse.
func merge(variables: [Key: Value], json: Value?) throws -> Value? {
    // TODO: The whole notion of this method smells - needs cleaning up.
    // variables:
    //    foo: json.method
    // -> variables = [foo: GET]

    func resolveJSONReference(responses: [Key: Value], value: Value) -> Value {
        let dict: Value = ["json": .dictionary(responses)]
        // FIXME: maybe allow subscript[value: Value] instead of referencing string here
        guard let resolved = dict[value.string] else { return value }
        return resolved
    }

    switch (variables, json) {
    case (_, .none):
        return .dictionary(variables)
    case (_, json?) where variables.isEmpty:
        return json
    case (_, .dictionary(let dict)?):
        let res: [Key: Value] = variables.mapValues { value in
            if let appendValue = value.appendValue {
                let resolved = resolveJSONReference(responses: dict, value: .string(appendValue))
                return .string(".append(\(resolved.string))")
            }
            return resolveJSONReference(responses: dict, value: value)
        }
        return .dictionary(res.merging(dict, strategy: .lastWins))
    case (_, .array(_)?), (_, .bool(_)?), (_, .string(_)?), (_, .int(_)?), (_, .double(_)?), (_, .null?):
        throw ResterError.internalError("Cannot merge variables unless response is a JSON object")
    }
}
