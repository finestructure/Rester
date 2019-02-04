import Commander
import Foundation
import Path
import PromiseKit
import Rainbow
import ResterCore
import Yams


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

        let rester = try Rester(path: restfilePath, workDir: workDir)

        if verbose {
            let vars = rester.aggregatedVariables
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

        let results = rester.test(
            before: { name in
                print("🎬  \(name.blue) started ...\n")
        }, after: { name, result in
            switch result {
            case .valid:
                print("✅  \(name.blue) \("PASSED".green.bold)\n")
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
            }
        })
            .done { results in
            let failureCount = results.filter({
                switch $0 {
                case .valid: return false
                default: return true
                }
            }).count
            let failureMsg = failureCount == 0 ? "0".green.bold : failureCount.description.red.bold
            print("Executed \(results.count.description.bold) tests, with \(failureMsg) failures")
            if failureCount > 0 {
                exit(1)
            }
        }

        wait(timeout: TimeInterval(rester.requestCount * 5)) { results.isFulfilled }


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
    } catch let error as ResterError {
        print("❌  Error: \(error.localizedDescription)")
        exit(1)
    } catch {
        print("❌  Error: \(error.localizedDescription)")
        exit(1)
    }
}


main.run()
