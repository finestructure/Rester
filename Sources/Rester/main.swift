import Commander
import Foundation
import Path
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


func getWorkDir(input: String) -> Path? {
    guard !input.isEmpty else { return nil }

    if let path = Path(input) {
        return path
    }

    // take is as relative path
    return Path.cwd/input
}


func debugPrint(_ msg: String) {
    print(msg.lightWhite.italic)
}


let main = command(
    Argument<String>("filename", description: "A Restfile"),
    Flag("verbose", flag: "v", description: "Verbose output"),
    Option<String>("workdir", default: "", flag: "w", description: "Working directory (for the purpose of resolving relative paths in Restfiles)")
) { filename, verbose, wdir in
    do {
        print("🚀  Resting \(filename.bold) ...\n")

        let restfilePath = Path(filename) ?? Path.cwd/filename
        let workDir = getWorkDir(input: wdir) ?? (restfilePath).parent

        if verbose {
            debugPrint("Restfile path: \(restfilePath)")
            debugPrint("Working directory: \(workDir)\n")
        }

        let yml = try String(contentsOf: restfilePath)

        let restfile = try YAMLDecoder().decode(Restfile.self, from: yml, userInfo: [.relativePath: workDir])

        if verbose {
            let vars = restfile.aggregatedVariables
            if vars.count > 0 {
                debugPrint("Defined variables:")
                for v in vars.keys {
                    debugPrint("  - \(v)")
                }
                print("")
            }
        }

        guard restfile.requestCount > 0 else {
            print("⚠️  no requests defined in \(filename.bold)!")
            exit(0)
        }

        var results = [Bool]()
        var chain = Promise()

        for req in try restfile.expandedRequests() {
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

    } catch let error as DecodingError {
        if
            case let .dataCorrupted(error) = error,
            let underlying = error.underlyingError {

            if let e = underlying as? ResterError {
                print("❌  \(e.localizedDescription)")
            } else {
                print("❌  Error: \(underlying.localizedDescription)")
            }
        } else {
            print("❌  Error: \(error.localizedDescription)")
        }
        exit(1)
    } catch {
        print("❌  Error: \(error.localizedDescription)")
        exit(1)
    }
}


main.run()
