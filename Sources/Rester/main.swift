import Commander
import Foundation
import PromiseKit
import Rainbow
import ResterCore
import Yams


func wait(timeout: TimeInterval, until: () -> Bool) {
    let runLoopModes = [RunLoop.Mode.default, RunLoop.Mode.common]
    let checkEveryInterval: TimeInterval = 0.01
    let runUntilDate = NSDate(timeIntervalSinceNow: timeout)
    var runIndex = 0

    while !until() {
        let mode = runLoopModes[runIndex % runLoopModes.count]
        runIndex += 1

        autoreleasepool {
            let checkDate = Date(timeIntervalSinceNow: checkEveryInterval)
            if !RunLoop.current.run(mode: mode, before: checkDate) {
                Thread.sleep(forTimeInterval: checkEveryInterval)
            }
        }

        if runUntilDate.compare(Date()) == .orderedAscending {
            break
        }
    }
}


func launch(request: Request, named name: String) throws -> Promise<Bool> {
    print("🎬  \(name.blue) started ...\n")
    return try request.test()
        .map {
            switch $0 {
            case .valid:
                print("✅  \(name.blue) \("PASSED".green.bold)\n")
                return true
            case .invalid(let message):
                print("❌  \(name.blue) \("FAILED".red.bold) : \(message.red)\n")
                return false
            }
    }
}


let main = command { (filename: String) in
    do {
        print("🚀  Resting \(filename.bold) ...\n")

        let yml = try String(contentsOfFile: filename)
        let rester = try YAMLDecoder().decode(Rester.self, from: yml)

        guard let requests = rester.requests else {
            print("⚠️  no requests defined in \(filename.bold)!\n")
            return
        }

        var results = [Bool]()
        var chain = Promise()

        // FIXME: run tests in order
        for name in requests.keys {
            chain = chain.then {
                try launch(request: try rester.request(name), named: name)
                    .map {
                        results.append($0)
                }
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
        print("Error: \(error)")
    }
}


main.run()
