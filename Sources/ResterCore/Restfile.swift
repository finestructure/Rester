import Foundation
import Path
import PromiseKit
import Yams


public struct Restfile {
    public let variables: [Key: Value]
    let requests: [Request]
    let restfiles: [Restfile]
}


extension Restfile: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variables = (try? container.decode([Key: Value].self, forKey: .variables)) ?? [:]

        if container.contains(.requests) {
            do {
                let req = try container.decode(OrderedDict<Request.Name, Request.Details>.self, forKey: .requests)
                requests = req.items.compactMap { $0.first }.map { Request(name: $0.key, details: $0.value) }
            } catch let DecodingError.keyNotFound(key, _) {
                throw ResterError.decodingError("key not found: \(key.stringValue)")
            }
        } else {
            requests = []
        }

        let paths = try? container.decode([Path].self, forKey: .restfiles)
        restfiles = try paths?.map { try Restfile(path: $0) } ?? []
    }

    enum CodingKeys: CodingKey {
        case variables
        case requests
        case restfiles
    }
}


extension Restfile {
    public init(path: Path, workDir: Path = Path.cwd) throws {
        if !path.exists {
            throw ResterError.fileNotFound(path.string)
        }
        let s = try String(contentsOf: path)
        self = try YAMLDecoder().decode(Restfile.self, from: s, userInfo: [.relativePath: workDir])
    }
}


func aggregate(variables: [Key: Value]?, from restfiles: [Restfile]?) -> [Key: Value] {
    let topLevelVariables = variables ?? [:]

    if let otherVariableDicts = restfiles?.compactMap({ $0.variables }) {
        return otherVariableDicts.reduce(topLevelVariables) { aggregate, next in
            aggregate.merging(next, strategy: .lastWins)
        }
    }

    return topLevelVariables
}


func aggregate(requests: [Request]?, from restfiles: [Restfile]?) -> [Request] {
    let topLevelRequests = requests ?? []

    if let otherRequests = restfiles?.compactMap({ $0.requests }) {
        return otherRequests.reduce(topLevelRequests, +)
    }

    return topLevelRequests
}
