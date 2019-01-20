import Foundation
import Regex
import PromiseKit


func _substitute(string: String, with variables: Variables) throws -> String {
    let regex = try Regex(pattern: "\\$\\{(.*?)\\}", groupNames: "variable")
    let res = regex.replaceAll(in: string) { match in
        if
            let varName = match.group(named: "variable"),
            let value = variables[varName]?.description {
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


public typealias Key = String
public typealias Variables = [Key: Value]


public struct Rester: Codable {
    public let variables: Variables?
    public let requests: [String: Request]?
}


extension Rester {
    public func request(_ requestName: String) throws -> Request {
        guard
            let requests = requests,
            let req = requests[requestName]
            else { throw ResterError.noSuchRequest(requestName) }
        if let variables = variables {
            return try req.substitute(variables: variables)
        }
        return req
    }
}
