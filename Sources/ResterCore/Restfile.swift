import Foundation
import Path
import PromiseKit
import Yams


public struct Restfile {
    // TODO: make these non-optional
    public let variables: [Key: Value]?
    let requests: [Request]?
    let restfiles: [Restfile]?
}


extension Restfile: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variables = try? container.decode([Key: Value].self, forKey: .variables)

        let req = try? container.decode(OrderedDict<Request.Name, Request.Details>.self, forKey: .requests)
        requests = req?.items.compactMap { $0.first }.map { Request(name: $0.key, details: $0.value) }

        let paths = try? container.decode([Path].self, forKey: .restfiles)
        restfiles = try paths?.map { try Restfile(path: $0) }
    }

    enum CodingKeys: CodingKey {
        case variables
        case requests
        case restfiles
    }
}


extension Restfile {
    init(path: Path) throws {
        if !path.exists {
            throw ResterError.fileNotFound(path)
        }
        let s = try String(contentsOf: path)
        self = try YAMLDecoder().decode(Restfile.self, from: s)
    }
}


extension Restfile {
    public var requestCount: Int {
        return aggregatedRequests.count
    }

    public var aggregatedVariables: [Key: Value] {
        let topLevelVariables = variables ?? [:]

        if let otherVariableDicts = restfiles?.compactMap({ $0.variables }) {
            return otherVariableDicts.reduce(topLevelVariables) { aggregate, next in
                aggregate.merging(next) { (_, new) in
                    return new  // later keys override earlier ones
                }
            }
        }

        return topLevelVariables
    }

    var aggregatedRequests: [Request] {
        let topLevelRequests = requests ?? []

        if let otherRequests = restfiles?.compactMap({ $0.requests }) {
            return otherRequests.reduce(topLevelRequests, +)
        }

        return topLevelRequests
    }

    public func expandedRequests() throws -> [Request] {
        return try aggregatedRequests.compactMap {
            try $0.substitute(variables: aggregatedVariables)
        }
    }

    public func expandedRequest(_ requestName: String) throws -> Request {
        guard let req = aggregatedRequests[requestName]
            else { throw ResterError.noSuchRequest(requestName) }
        return try req.substitute(variables: aggregatedVariables)
    }
}
