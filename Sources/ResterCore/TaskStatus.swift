enum TaskStatus<T> {
    case inProgress(Task<T, Error>)
    case idle
    case cancelled

    var task: Task<T, Error>? {
        switch self {
            case .cancelled, .idle:
                return nil
            case .inProgress(let task):
                return task
        }
    }

    var value: T? {
        get async throws {
            switch self {
                case .cancelled, .idle:
                    return nil
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
}
