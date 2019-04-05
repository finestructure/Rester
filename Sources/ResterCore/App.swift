//
//  Main.swift
//  ResterCore
//
//  Created by Sven A. Schmidt on 05/04/2019.
//

import Commander
import Foundation
import Path


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


public let app = command(
    Flag("verbose", flag: "v", description: "Verbose output"),
    Option<String>("workdir", default: "", flag: "w", description: "Working directory (for the purpose of resolving relative paths in Restfiles)"),
    Option<TimeInterval>("timeout", default: 10, flag: "t", description: "Request timeout"),
    Flag("insecure", default: false, description: "do not validate SSL certificate (macOS only)"),
    Argument<String>("filename", description: "A Restfile")
) { verbose, wdir, timeout, insecure, filename in

    #if !os(macOS)
    if insecure {
        Current.console.display("--insecure flag currently only supported on macOS")
        exit(1)
    }
    #endif

    Current.console.display("🚀  Resting \(filename.bold) ...\n")

    let restfilePath = Path(filename) ?? Path.cwd/filename
    Current.workDir = getWorkDir(input: wdir) ?? (restfilePath).parent

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
        Current.console.display(error)
        exit(1)
    }

    if verbose {
        Current.console.display(variables: rester.allVariables)
    }

    guard rester.requestCount > 0 else {
        Current.console.display("⚠️  no requests defined in \(filename.bold)!")
        exit(0)
    }

    rester.test(before: before, after: after, timeout: timeout, validateCertificate: !insecure)
        .done { results in
            let failureCount = results.filter { !$0 }.count
            let failureMsg = failureCount == 0 ? "0".green.bold : failureCount.description.red.bold
            Current.console.display("Executed \(results.count.description.bold) tests, with \(failureMsg) failures")
            if failureCount > 0 {
                exit(1)
            } else {
                exit(0)
            }
        }.catch { error in
            Current.console.display(error)
            exit(1)
    }

    RunLoop.main.run()

}
