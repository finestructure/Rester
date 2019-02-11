import Commander
import Foundation
import LegibleError
import Path
import PromiseKit
import Rainbow
import ResterCore
import Yams


func debugPrint(_ msg: String) {
    print(msg.lightWhite.italic)
}


func display(_ error: Error) {
    print("❌  Error: \(error.legibleLocalizedDescription)")
}


let main = command(
    Argument<String>("filename", description: "A Restfile"),
    Flag("verbose", flag: "v", description: "Verbose output"),
    Option<String>("workdir", default: "", flag: "w", description: "Working directory (for the purpose of resolving relative paths in Restfiles)")
) { filename, verbose, wdir in

    print("🚀  Resting \(filename.bold) ...\n")

    let restfilePath = Path(filename) ?? Path.cwd/filename
    let workDir = getWorkDir(input: wdir) ?? (restfilePath).parent

    if verbose {
        debugPrint("Restfile path: \(restfilePath)")
        debugPrint("Working directory: \(workDir)\n")
    }

    let rester: Rester
    do {
        rester = try Rester(path: restfilePath, workDir: workDir)
    } catch {
        exit(1)
    }

    if verbose {
        let vars = rester.allVariables
        if vars.count > 0 {
            debugPrint("Defined variables:")
            for v in vars.keys {
                debugPrint("  - \(v)")
            }
            print("")
        }
    }

    guard rester.requestCount > 0 else {
        print("⚠️  no requests defined in \(filename.bold)!")
        exit(0)
    }

    let results = rester.test(before: { name in
        print("🎬  \(name.blue) started ...\n")
    }, after: { name, result -> Bool in
        switch result {
        case .valid:
            print("✅  \(name.blue) \("PASSED".green.bold)\n")
            return true
        case let .invalid(message, response: response):
            if verbose {
                if let response = response {
                    debugPrint("Response was:")
                    debugPrint("\(response)")
                } else {
                    debugPrint("Response was nil")
                }
                print("")
            }
            print("❌  \(name.blue) \("FAILED".red.bold) : \(message.red)\n")
            return false
        }
    }).done { results in
        let failureCount = results.filter { !$0 }.count
        let failureMsg = failureCount == 0 ? "0".green.bold : failureCount.description.red.bold
        print("Executed \(results.count.description.bold) tests, with \(failureMsg) failures")
        if failureCount > 0 {
            exit(1)
        }
    }
    _ = results.catch { error in
        display(error)
        exit(1)
    }

    wait(timeout: TimeInterval(rester.requestCount * 5)) { results.isFulfilled }
    if !results.isFulfilled {
        print("❌  Error: request timed out\n")
        exit(1)
    }

}


main.run()
