//
//  Main.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 05/04/2019.
//

import Commander
import Foundation
import Path
import PromiseKit


func before(name: Request.Name) {
    Current.console.display("🎬  \(name.blue) started ...\n")
}


func after(name: Request.Name, response: Response, result: ValidationResult) -> Bool {
    switch result {
    case .valid:
        let duration = format(response.elapsed).map { " (\($0)s)" } ?? ""
        Current.console.display("✅  \(name.blue) \("PASSED".green.bold)\(duration)\n")
        return true
    case let .invalid(message):
        Current.console.display(verbose: "Response:".bold)
        Current.console.display(verbose: "\(response)\n")
        Current.console.display("❌  \(name.blue) \("FAILED".red.bold) : \(message.red)\n")
        return false
    }
}


func process(_ filename: String, insecure: Bool, timeout: TimeInterval, verbose: Bool, workdir: String) -> Promise<[Bool]> {
    Current.console.display("🚀  Resting \(filename.bold) ...\n")

    let restfilePath = Path(filename) ?? Path.cwd/filename
    Current.workDir = getWorkDir(input: workdir) ?? (restfilePath).parent

    if verbose {
        Current.console.display(verbose: "Restfile path: \(restfilePath)")
        Current.console.display(verbose: "Working directory: \(Current.workDir)\n")
    }

    if timeout != Request.defaultTimeout {
        Current.console.display(verbose: "Request timeout: \(timeout)s\n")
    }

    let rester: Rester
    do {
        rester = try Rester(path: restfilePath, workDir: Current.workDir)
    } catch {
        return Promise(error: error)
    }

    if verbose {
        Current.console.display(variables: rester.allVariables)
    }

    guard rester.requestCount > 0 else {
        Current.console.display("⚠️  no requests defined in \(filename.bold)!")
        return .value([Bool]())
    }

    return rester.test(before: before, after: after, timeout: timeout, validateCertificate: !insecure)
}


public let app = command(
    Flag("insecure", default: false, description: "do not validate SSL certificate (macOS only)"),
    Option<Int?>("loop", default: .none, flag: "l", description: "keep executing file every <loop> seconds"),
    Option<TimeInterval>("timeout", default: Request.defaultTimeout, flag: "t", description: "Request timeout"),
    Flag("verbose", flag: "v", description: "Verbose output"),
    Option<String>("workdir", default: "", flag: "w", description: "Working directory (for the purpose of resolving relative paths in Restfiles)"),
    Argument<String>("filename", description: "A Restfile")
) { insecure, loop, timeout, verbose, workdir, filename in

    signal(SIGINT) { s in
        print("\nInterrupted by user, terminating ...")
        exit(0)
    }

    #if !os(macOS)
    if insecure {
        Current.console.display("--insecure flag currently only supported on macOS")
        exit(1)
    }
    #endif

    if let loop = loop {
        print("Running every \(loop) seconds ...\n")
        var grandTotal = 0
        var failedTotal = 0
        var chain = Promise()
        while true {
            chain = chain.then { _ -> Promise<Void> in
                process(filename, insecure: insecure, timeout: timeout, verbose: verbose, workdir: workdir)
                    .done { results in
                        let failureCount = results.filter { !$0 }.count
                        grandTotal += results.count
                        failedTotal += failureCount
                        Current.console.display(summary: results.count, failed: failureCount)
                }
            }
            // FIXME: .catch { error  ... somehow (does not compile atm)
            RunLoop.main.run(until: Date(timeIntervalSinceNow: TimeInterval(loop)))
            Current.console.display("")
            Current.console.display("TOTAL: ", terminator: "")
            Current.console.display(summary: grandTotal, failed: failedTotal)
            Current.console.display("")
        }
    } else {
        _ = process(filename, insecure: insecure, timeout: timeout, verbose: verbose, workdir: workdir)
            .done { results in
                let failureCount = results.filter { !$0 }.count
                Current.console.display(summary: results.count, failed: failureCount)
                if failureCount > 0 {
                    exit(1)
                } else {
                    exit(0)
                }
            }.catch { error in
                Current.console.display(error)
                exit(1)
        }
    }

    RunLoop.main.run()
}
