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
    if
        let decodingError = error as? DecodingError,
        case let .dataCorrupted(err) = decodingError,
        let underlying = err.underlyingError as? ResterError {
        print("❌  Restfile syntax error: \(underlying.legibleLocalizedDescription)")
    } else {
        print("❌  Error: \(error.legibleLocalizedDescription)")
    }
}


let main = command(
    Flag("verbose", flag: "v", description: "Verbose output"),
    Option<String>("workdir", default: "", flag: "w", description: "Working directory (for the purpose of resolving relative paths in Restfiles)"),
    Option<TimeInterval>("timeout", default: 5, flag: "t", description: "Request timeout"),
    Argument<String>("filename", description: "A Restfile")
) { verbose, wdir, timeout, filename in

    print("🚀  Resting \(filename.bold) ...\n")

    let restfilePath = Path(filename) ?? Path.cwd/filename
    let workDir = getWorkDir(input: wdir) ?? (restfilePath).parent

    if verbose {
        debugPrint("Restfile path: \(restfilePath)")
        debugPrint("Working directory: \(workDir)\n")
    }

    if timeout != Request.defaultTimeout {
        Current.console.display(verbose: "Request timeout: \(timeout)s\n")
    }

    let rester: Rester
    do {
        rester = try Rester(path: restfilePath, workDir: workDir)
    } catch {
        display(error)
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

    func before(name: Request.Name) {
        print("🎬  \(name.blue) started ...\n")
    }

    func after(name: Request.Name, response: Response, result: ValidationResult) -> Bool {
        switch result {
        case .valid:
            let duration = format(response.elapsed).map { " (\($0)s)" } ?? ""
            print("✅  \(name.blue) \("PASSED".green.bold)\(duration)\n")
            return true
        case let .invalid(message):
            if verbose {
                debugPrint("Response was:")
                debugPrint("\(response)\n")
            }
            print("❌  \(name.blue) \("FAILED".red.bold) : \(message.red)\n")
            return false
        }
    }

    rester.test(before: before, after: after, timeout: timeout)
        .done { results in
            let failureCount = results.filter { !$0 }.count
            let failureMsg = failureCount == 0 ? "0".green.bold : failureCount.description.red.bold
            print("Executed \(results.count.description.bold) tests, with \(failureMsg) failures")
            if failureCount > 0 {
                exit(1)
            } else {
                exit(0)
            }
        }.catch { error in
            display(error)
            exit(1)
    }

    RunLoop.main.run()

}


main.run()
