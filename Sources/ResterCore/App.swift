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

    @Flag(name: .shortAndLong, help: "log JSON result")
    var json = false

    @Option(name: .shortAndLong, help: "keep executing file every <loop> seconds")
    var loop: Double?

    @Flag(name: .shortAndLong, help: "Show stats")
    var stats = false

    @Option(name: .shortAndLong, help: "Request timeout")
    var timeout: TimeInterval = Request.defaultTimeout

    @Flag(name: .shortAndLong, help: "Verbose output")
    var verbose = false

    @Flag(name: .customLong("version"), help: "Show version")
    var showVersion = false

    @Option(name: .shortAndLong,
            help: "Working directory (for the purpose of resolving relative paths in Restfiles)")
    var workdir = ""

    @Argument(help: "A Restfile")
    var filename: String?

    public init() {}

    public mutating func run() throws {

        signal(SIGINT) { s in
            print("\nInterrupted by user, terminating ...")
            App.exit(0)
        }

#if !os(macOS)
        if insecure {
            Current.console.display("--insecure flag currently only supported on macOS")
            App.exit(1)
        }
#endif

        if showVersion {
            print("Version: \(ResterVersion)")
            App.exit(0)
        }

        guard let filename = filename else {
            throw ValidationError("Error: Missing expected argument '<filename>'")
        }

        if stats {
            statistics = [:]
        }

        let rester: Rester
        do {
            rester = try read(restfile: filename, timeout: timeout, verbose: verbose, workdir: workdir)
        } catch {
            Current.console.display(error)
            App.exit(1)
        }

        if count != nil && duration != nil {
            Current.console.display("⚠️  Both count and duration specified, using count.\n")
        }

        if json {
            Current.console = JsonConsole()
        }

        // avoid self-captures
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

                    App.exit(globalResults.failureCount == 0 ? 0 : 1)
                } catch {
                    Current.console.display(error)
                    App.exit(1)
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
                    App.exit(results.failureCount == 0 ? 0 : 1)
                } catch {
                    Current.console.display(error)
                    App.exit(1)
                }
            }
        }

        RunLoop.main.run()
    }

    static func exit(_ returnCode: Int32) -> Never {
        fflush(stdout)
        fflush(stderr)
        _exit(returnCode)
    }
}
