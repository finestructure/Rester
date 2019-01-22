import Commander
import Foundation
import PromiseKit
import Rainbow
import ResterCore
import Yams


func _autoreleasepool(block: () -> ()) {
    #if os(Linux)
    block()
    #else
    autoreleasepool { block() }
    #endif
}


func wait(timeout: TimeInterval, condition: () -> Bool) {
    #if os(Linux)
    let runLoopModes = [RunLoopMode.defaultRunLoopMode, RunLoopMode.commonModes]
    #else
    let runLoopModes = [RunLoop.Mode.default, RunLoop.Mode.common]
    #endif

    let pollingInterval: TimeInterval = 0.01
    let endDate = NSDate(timeIntervalSinceNow: timeout)
    var index = 0

    while !condition() {
        let mode = runLoopModes[index % runLoopModes.count]
        let checkDate = Date(timeIntervalSinceNow: pollingInterval)
        index += 1

        _autoreleasepool {
            if !RunLoop.current.run(mode: mode, before: checkDate) {
                Thread.sleep(forTimeInterval: pollingInterval)
            }
        }

        if endDate.compare(Date()) == .orderedAscending {
            break
        }
    }
}


func launch(request: Request) throws -> Promise<Bool> {
    print("🎬  \(request.name.blue) started ...\n")
    return try request.test()
        .map {
            switch $0 {
            case .valid:
                print("✅  \(request.name.blue) \("PASSED".green.bold)\n")
                return true
            case .invalid(let message):
                print("❌  \(request.name.blue) \("FAILED".red.bold) : \(message.red)\n")
                return false
            }
    }
}


let main = command { (filename: String) in
    do {
        print("🚀  Resting \(filename.bold) ...\n")

        let yml = try String(contentsOfFile: filename)
        let rester = try YAMLDecoder().decode(Rester.self, from: yml)

        guard rester.requestCount > 0 else {
            print("⚠️  no requests defined in \(filename.bold)!")
            exit(0)
        }

        var results = [Bool]()
        var chain = Promise()

        for req in try rester.expandedRequests() {
            chain = chain.then {
                try launch(request: req).map { results.append($0) }
            }
        }

        var done = false
        _ = chain.done {
            done = true
        }
        wait(timeout: 10) { done }

        let failureCount = results.filter { !$0 }.count
        let failureMsg = failureCount == 0 ? "0".green.bold : failureCount.description.red.bold
        print("Executed \(results.count.description.bold) tests, with \(failureMsg) failures")
        if failureCount > 0 {
            exit(1)
        }

    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
}


main.run()
