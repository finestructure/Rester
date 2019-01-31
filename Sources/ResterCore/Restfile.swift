import Foundation
import Path
import PromiseKit
import Yams


public struct Restfile {
    public let variables: [Key: Value]?
    let requests: [Request]?
    let restfiles: [Path]?
}


extension Restfile: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variables = try? container.decode([Key: Value].self, forKey: .variables)
        do {
            let req = try? container.decode(OrderedDict<Request.Name, Request.Details>.self, forKey: .requests)
            requests = req?.items.compactMap { $0.first }.map { Request(name: $0.key, details: $0.value) }
        }
        restfiles = try? container.decode([Path].self, forKey: .restfiles)
    }

    enum CodingKeys: CodingKey {
        case variables
        case requests
        case restfiles
    }
}


extension Restfile {
    init(path: Path) throws {
        let s = try String(contentsOf: path)
        self = try YAMLDecoder().decode(Restfile.self, from: s)
    }
}


extension Restfile {
    public var requestCount: Int {
        return requests?.count ?? 0
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
            let req = requests?.first(where: { $0.name == requestName } )
            else { throw ResterError.noSuchRequest(requestName) }
        if let variables = variables {
            return try req.substitute(variables: variables)
        }
        return req
    }
}
