import Foundation
import Regex
import PromiseKit


func _substitute(string: String, with variables: Variables) throws -> String {
    let regex = try Regex(pattern: "\\$\\{(.*?)\\}", groupNames: "variable")
    let res = regex.replaceAll(in: string) { match in
        if
            let varName = match.group(named: "variable"),
            let value = variables[varName]?.substitutionDescription {
            return value
        } else {
            return nil
        }
    }

    if res =~ regex {
        throw ResterError.undefinedVariable("Undefined variable: \(res)")
    }
    return res
}


public typealias Variables = [Key: Value]


public struct Rester: Decodable {
    public let variables: Variables?
    let requests: Requests?
}


extension Rester {
    public var requestCount: Int {
        return requests?.items.count ?? 0
    }

    public func expandedRequests() throws -> [Request] {
        guard
            let requests = requests,
            let variables = variables
            else { return [] }
        return try requests.compactMap {
            try $0.substitute(variables: variables)
        }
    }

    public func expandedRequest(_ requestName: String) throws -> Request {
        guard
            let req = requests?[requestName]
            else { throw ResterError.noSuchRequest(requestName) }
        if let variables = variables {
            return try req.substitute(variables: variables)
        }
        return req
    }
}
