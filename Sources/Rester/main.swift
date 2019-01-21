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


func launch(request: Request, named name: String) throws -> Promise<Void> {
    print("→  \(name.blue) started ...")
    return try request.test()
        .map {
            switch $0 {
            case .valid:
                print("✅  \(name.blue) \("PASSED".green.bold)")
            case .invalid(let message):
                print("❌  \(name.blue) \("FAILED".red.bold) : \(message.red)")
            }
    }
}


let main = command { (filename: String) in
    do {
        print("→  Resting \(filename.bold) ...")

        let yml = try String(contentsOfFile: filename)
        let rester = try YAMLDecoder().decode(Rester.self, from: yml)

        guard let requests = rester.requests else {
            print("⚠️  no requests defined in \(filename.bold)!")
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
