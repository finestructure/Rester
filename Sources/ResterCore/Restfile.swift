import Foundation
import Path
import PromiseKit
import Yams


public struct Restfile {
    public let variables: [Key: Value]
    let requests: [Request]
    let restfiles: [Restfile]
    let setupRequests: [Request]
}


extension Restfile: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        variables = (try? container.decode([Key: Value].self, forKey: .variables)) ?? [:]
        requests = try container.decodeRequests(for: .requests)
        do {
            let paths = try? container.decode([Path].self, forKey: .restfiles)
            restfiles = try paths?.map { try Restfile(path: $0) } ?? []
        }
        setupRequests = try container.decodeRequests(for: .setupRequests)
    }

    enum CodingKeys: String, CodingKey {
        case variables
        case requests
        case restfiles
        case setupRequests = "set_up"
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
