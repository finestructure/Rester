import ArgumentParser
import Foundation
import Path


var statistics: [Request.Name: Stats]? = nil


func before(name: Request.Name) {
    Current.console.display("🎬  \(name.blue) started ...\n")
}


func after(result: TestResult) {
    switch result {
    case let .success(name, response):
        let duration = format(response.elapsed).map { " (\($0)s)" } ?? ""
        Current.console.display("✅  \(name.blue) \("PASSED".green.bold)\(duration)\n")
        if statistics != nil {
            statistics?[name, default: Stats()].add(response.elapsed)
            Current.console.display(statistics)
        }
    case let .failure(name, response, reason):
        Current.console.display(verbose: "Response:".bold)
        Current.console.display(verbose: "\(response)\n")
        Current.console.display("❌  \(name.blue) \("FAILED".red.bold) : \(reason.red)\n")
    case let .skipped(name):
        Current.console.display("↪️   \(name.blue) \("SKIPPED".yellow)\n")
    }
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


public struct App: ParsableCommand {
    @Option(name: .shortAndLong,
            help: "number of iterations to loop for (implies `--loop 0`)")
    var count: Int?

    @Option(name: .shortAndLong, help: "duration <seconds> to loop for (implies `--loop 0`")
    var duration: Double?

    @Flag(help: "do not validate SSL certificate (macOS only)")
    var insecure = false

    @Option(name: .shortAndLong, help: "keep executing file every <loop> seconds")
    var loop: Double?

    @Flag(name: .shortAndLong, help: "Show stats")
    var stats = false

    @Option(name: .shortAndLong, help: "Request timeout")
    var timeout: TimeInterval = Request.defaultTimeout

    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose = false

    @Option(name: .shortAndLong,
            help: "Working directory (for the purpose of resolving relative paths in Restfiles)")
    var workdir = ""

    @Argument(help: "A Restfile")
    var filename: String

    public init() {}

    public mutating func run() throws {

        signal(SIGINT) { s in
            print("\nInterrupted by user, terminating ...")
            App.exit(withError: nil)
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
            // TODO: drop the above line after checking what it looks like
            // i.e. this will a duplicate error, choose one: either
            // console.display(error)
            // throw ExitCode(xxx)
            // or just let the error bubble up (probably the former)
            //            throw error
            App.exit(withError: error)
        }

        if count != nil && duration != nil {
            Current.console.display("⚠️  Both count and duration specified, using count.\n")
        }

        // avoid self-captures
        let filename = filename
        let timeout = timeout
        let insecure = insecure

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

                    _exit(globalResults.failureCount == 0 ? 0 : 1)
                } catch {
                    Current.console.display(error)
                    App.exit(withError: error)
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
                    _exit(results.failureCount == 0 ? 0 : 1)
                } catch {
                    Current.console.display(error)
                    App.exit(withError: error)
                }
            }
        }

        RunLoop.main.run()
    }
}
