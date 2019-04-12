import Foundation
import Path
import PromiseKit
import Yams


enum Mode: String, Decodable {
    case sequential
    case random
}


public struct Restfile {
    public let variables: [Key: Value]
    let requests: [Request]
    let restfiles: [Restfile]
    let setupRequests: [Request]
    let mode: Mode
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
        mode = (try? container.decode(Mode.self, forKey: .mode)) ?? .sequential
    }

    enum CodingKeys: String, CodingKey {
        case variables
        case requests
        case restfiles
        case setupRequests = "set_up"
        case mode
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

