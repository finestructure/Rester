import Foundation
import PromiseKit


@available(*, deprecated, message: "Use loop(...) async instead")
public func run<T>(_ interation: Iteration, interval: DispatchTimeInterval = .seconds(2), _ body: @escaping () -> Promise<T>) -> Promise<T> {
    var iteration = interation
    func loop() -> Promise<T> {
        iteration = iteration.incremented
        if iteration.done {
            return body()
        }
        return body().then { res in
            return after(interval).then(on: nil, loop)
        }
    }
    return loop()
}



