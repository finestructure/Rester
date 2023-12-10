actor Runner<T> {
    private var activeTask: Status<T> = .idle

    func run(_ block: @escaping () async throws -> T) throws {
        guard !activeTask.isCancelled else { throw CancellationError() }
        if !activeTask.isIdle {
            activeTask.cancel()
        }

        activeTask = .inProgress(Task {
            try await block()
        })
    }

    var value: T { get async throws { try await activeTask.value } }

    func cancel() { activeTask.cancel() }
}

extension Runner {
    enum Status<U> {
        case inProgress(Task<U, Error>)
        case idle
        case cancelled

        var value: U {
            get async throws {
                switch self {
                    case .cancelled, .idle:
                        throw CancellationError()
                    case .inProgress(let task):
                        return try await task.value
                }
            }
        }

        mutating func cancel() {
            switch self {
                case .cancelled:
                    break
                case .idle:
                    self = .cancelled
                case .inProgress(let task):
                    task.cancel()
                    self = .cancelled
            }
        }

        var isCancelled: Bool {
            switch self {
                case .cancelled:
                    return true
                case .inProgress, .idle:
                    return false
            }
        }

        var isIdle: Bool {
            switch self {
                case .cancelled, .inProgress:
                    return false
                case .idle:
                    return true
            }
        }
    }

}
