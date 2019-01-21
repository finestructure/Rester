import Commander
import Foundation
import PromiseKit
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


func launch(request: Request, named name: String) throws -> Promise<Void> {
    print("→  Starting request '\(name)' ...")
    return try request.test()
        .map {
            switch $0 {
            case .valid:
                print("✅  \(name) PASSED")
            case .invalid(let message):
                print("❌  \(name) FAILED: \(message)")
            }
    }
}


let main = command { (filename: String) in
    do {
        print("→  Resting '\(filename)' ...")

        let yml = try String(contentsOfFile: filename)
        let rester = try YAMLDecoder().decode(Rester.self, from: yml)

        guard let requests = rester.requests else {
            print("⚠️  no requests defined in '\(filename)'!")
            return
        }

        var chain = Promise()
        for name in requests.keys {
            chain = chain.then { try launch(request: try rester.request(name), named: name) }
        }

        var done = false
        _ = chain.done {
            print("Done.")
            done = true
        }
        wait(timeout: 10) { done }

    } catch {
        print("Error: \(error)")
    }
}


main.run()
