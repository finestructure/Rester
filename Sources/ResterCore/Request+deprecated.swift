import Foundation
import PMKFoundation
import PromiseKit


extension Request {

    @available(*, deprecated)
    public func execute(timeout: TimeInterval = Request.defaultTimeout, validateCertificate: Bool = true) throws -> Promise<Response> {

        guard let url = url else { throw ResterError.invalidURL(self.details.url) }

        self.sessionDelegate.validateCertificate = validateCertificate

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if [.post, .put].contains(method), let body = body {
            switch body {
            case let .json(body):
                if let postData = try? JSONEncoder().encode(body) {
                    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = postData
                }
            case let .form(body):
                if let postData = body.formUrlEncoded.data(using: .utf8) {
                    urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = postData
                }
            case let .multipart(body):
                urlRequest.addValue(
                    "multipart/form-data; charset=utf-8; boundary=__X_RESTER_BOUNDARY__",
                    forHTTPHeaderField: "Content-Type"
                )
                urlRequest.httpBody = try body.multipartEncoded()
            case let .text(body):
                urlRequest.addValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = body.data(using: .utf8)
            case let .file(file):
                let path = try file.path()
                urlRequest.addValue(path.mimeType, forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = try Data(contentsOf: path)
            }
        }
        headers.forEach {
            urlRequest.addValue($0.value.string, forHTTPHeaderField: $0.key)
        }

        if delay > 0 {
            Current.console.display(verbose: "Delaying for \(delay)s")
        }

        let request = after(seconds: delay)
            .then { () -> Promise<(start: Date, response: (data: Data, response: URLResponse))> in
                let start = Date()
                return self.session.dataTask(.promise, with: urlRequest).map { (start: start, response: $0)}
            }.map {
                try Response(
                    elapsed: Date().timeIntervalSince($0.start),
                    data: $0.response.data,
                    response: $0.response.response,
                    variables: self.variables
                )
            }.map { Result<Response>.fulfilled($0) }

        let timeout: Promise<Result<Response>> = after(seconds: delay + timeout).map { _ in
            .rejected(ResterError.timeout(requestName: self.name))
        }

        return race(request, timeout)
            .map { winner -> Response in
                switch winner {
                case .fulfilled(let result):
                    return result
                case .rejected(let error):
                    throw error
                }
            }.map { response in
                if let value = self.log { try _log(value: value, of: response) }
                return response
        }
    }

    // TODO: remove - it's only used in tests
    @available(*, deprecated)
    public func test() throws -> Promise<ValidationResult> {
        return try execute().map { self.validate($0) }
    }

}
