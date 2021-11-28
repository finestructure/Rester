import Commander
import Foundation
import Path


var statistics: [Request.Name: Stats]? = nil


func before(name: Request.Name) {
    Current.console.display("🎬  \(name.blue) started ...\n")
}


// FIXME: make this (Request.Name, TestResult) -> Void?
func after(name: Request.Name, result: TestResult) -> TestResult {
    switch result {
    case .success(let response):
        let duration = format(response.elapsed).map { " (\($0)s)" } ?? ""
        Current.console.display("✅  \(name.blue) \("PASSED".green.bold)\(duration)\n")
        if statistics != nil {
            statistics?[name, default: Stats()].add(response.elapsed)
            Current.console.display(statistics)
        }
    case let .failure(response, reason):
        Current.console.display(verbose: "Response:".bold)
        Current.console.display(verbose: "\(response)\n")
        Current.console.display("❌  \(name.blue) \("FAILED".red.bold) : \(reason.red)\n")
    case .skipped:
        Current.console.display("↪️   \(name.blue) \("SKIPPED".yellow)\n")
    }
    return result
}


func read(restfile: String, timeout: TimeInterval, verbose: Bool, workdir: String) throws -> Rester {
    let restfilePath = Path(restfile) ?? Path.cwd/restfile
    Current.workDir = getWorkDir(input: workdir) ?? (restfilePath).parent

    if verbose {
        Current.console.display(verbose: "Restfile path: \(restfilePath)")
        Current.console.display(verbose: "Working directory: \(Current.workDir)\n")
    }

    if timeout != Request.defaultTimeout {
        Current.console.display(verbose: "Request timeout: \(timeout)s\n")
    }

    let rester = try Rester(path: restfilePath, workDir: Current.workDir)

    if verbose {
        Current.console.display(variables: rester.variables)
    }

    guard rester.requests.count > 0 else {
        throw ResterError.genericError("⚠️  no requests defined in \(restfile.bold)!")
    }

    return rester
}


public let app = command(
    Flag("insecure", default: false, description: "do not validate SSL certificate (macOS only)"),
    Option<Int?>("count", default: .none, flag: "c",
                 description: "number of iterations to loop for (implies `--loop 0`)"),
    Option<Double?>("duration", default: .none, flag: "d",
                    description: "duration <seconds> to loop for (implies `--loop 0`"),
    Option<Double?>("loop", default: .none, flag: "l",
                    description: "keep executing file every <loop> seconds"),
    Flag("stats", flag: "s", description: "Show stats"),
    Option<TimeInterval>("timeout", default: Request.defaultTimeout, flag: "t", description: "Request timeout"),
    Flag("verbose", flag: "v", description: "Verbose output"),
    Option<String>("workdir", default: "", flag: "w",
                   description: "Working directory (for the purpose of resolving relative paths in Restfiles)"),
    Argument<String>("filename", description: "A Restfile")
) { insecure, count, duration, loop, stats, timeout, verbose, workdir, filename in

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

    if stats {
        statistics = [:]
    }

    let rester: Rester
    do {
        rester = try read(restfile: filename, timeout: timeout, verbose: verbose, workdir: workdir)
    } catch {
        Current.console.display(error)
        exit(1)
    }

    if count != nil && duration != nil {
        Current.console.display("⚠️  Both count and duration specified, using count.\n")
    }

    if let loop = loopParameters(count: count, duration: duration, loop: loop) {
        print("Running every \(loop.delay) seconds ...\n")

        Task {
            do {
                var iter = loop.iteration
                var firstIteration = true
                var globalResults = [TestResult]()

                while !iter.done {
                    defer {
                        iter.increment()
                        firstIteration = false
                    }

                    if !firstIteration {
                        try await Task.sleep(seconds: loop.delay)
                    }

                    Current.console.display("🚀  Resting \(filename.bold) ...\n")
                    let results = try await rester.test(before: before,
                                                        after: after,
                                                        timeout: timeout,
                                                        validateCertificate: !insecure,
                                                        runSetup: firstIteration)
                    globalResults += results
                    Current.console.display(results: results)
                    Current.console.display("")
                    Current.console.display("TOTAL: ", terminator: "")
                    Current.console.display(results: globalResults)
                    Current.console.display("")
                }

                exit(globalResults.failureCount == 0 ? 0 : 1)
            } catch {
                Current.console.display(error)
                exit(1)
            }
        }
    } else {
        Current.console.display("🚀  Resting \(filename.bold) ...\n")
        Task {
            do {
                let results = try await rester.test(before: before,
                                                    after: after,
                                                    timeout: timeout,
                                                    validateCertificate: !insecure)
                Current.console.display(results: results)
                exit(results.failureCount == 0 ? 0 : 1)
            } catch {
                Current.console.display(error)
                exit(1)
            }
        }
    }

    RunLoop.main.run()
}
