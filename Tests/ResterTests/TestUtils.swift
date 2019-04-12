//
//  TestUtils.swift
//  ResterTests
//
//  Created by Sven A. Schmidt on 30/01/2019.
//

import Foundation
import Path
import Regex
import ResterCore


func path(fixture: String) -> Path? {
    return testDataDirectory()?.join(fixture)
}


func path(example: String) -> Path? {
    return examplesDirectory()?.join(example)
}


func read(fixture: String) throws -> String? {
    guard let file = path(fixture: fixture) else { return nil }
    return try String(contentsOf: file)
}


func read(example: String) throws -> String? {
    guard let file = path(example: example) else { return nil }
    return try String(contentsOf: file)
}


var productsDirectory: URL {
    #if os(macOS)
    for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
    }
    fatalError("couldn't find the products directory")
    #else
    return Bundle.main.bundleURL
    #endif
}


func testDataDirectory(path: String = #file) -> Path? {
    return Path(path)?.parent.join("TestData")
}


func examplesDirectory(path: String = #file) -> Path? {
    return Path(path)?.parent.parent.parent.join("examples")
}


extension ValidationResult: Equatable {
    public static func == (lhs: ValidationResult, rhs: ValidationResult) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid):
            return true
        case (.invalid(let x), .invalid(let y)):
            return x == y
        default:
            return false
        }
    }
}


class TestConsole: Console {
    var messages = [String]()
    var keys = [String]()
    var values = [Any]()
    var verbose = [String]()
    var error: String = ""

    func display(_ message: String, terminator: String) {
        messages.append(message)
    }

    func display(key: String, value: Any) {
        keys.append(key)
        values.append(value)
    }

    func display(verbose message: String) {
        self.verbose.append(message)
    }

    func display(_ error: Error) {
        self.error.append(error.legibleLocalizedDescription + "\n")
    }
}


// Convenience accessors
extension Body {
    var json: [Key: Value]? { if case let .json(value) = self { return value } else { return nil } }
    var form: [Key: Value]? { if case let .form(value) = self { return value } else { return nil } }
    var multipart: [Key: Value]? { if case let .multipart(value) = self { return value } else { return nil } }
    var text: String? { if case let .text(value) = self { return value } else { return nil } }
    var file: Value? { if case let .file(value) = self { return value } else { return nil } }
}


enum TestError: Error {
    case runtimeError(String)
}


extension String {
    var maskTime: String {
        // select 2+ decimal places to capture the timings (which are typically longers)
        // and not the timeout parameter (e.g. "Request timeout: 7.0s")
        if let regex = try? Regex(pattern: "\\d+\\.\\d{2,}s") {
            return regex.replaceAll(in: self, with: "X.XXXs")
        } else {
            return self
        }
    }

    func maskPath(_ path: Path, with placeholder: String? = nil) -> String {
        let placeholder = path.isDirectory ? (placeholder ?? "XXX") : path.basename()
        return path.string.r?.replaceAll(in: self, with: placeholder) ?? self
    }

    func maskLine(prefix: String) -> String {
        // Should really use '^' instead of '\n' at the start of the pattern but
        // it fails to match anything in that case
        if let regex = try? Regex(pattern: "\n\(prefix)[^\n]*") {
            return regex.replaceAll(in: self, with: "\n\(prefix)<non-deterministic output masked>")
        } else {
            return self
        }
    }
}


func launch(with requestFile: Path, extraArguments: [String] = []) throws -> (status: Int32, output: String) {
    // Some of the APIs that we use below are available in macOS 10.13 and above.
    guard #available(macOS 10.13, *) else {
        throw TestError.runtimeError("unsupported OS")
    }

    let binary = productsDirectory.appendingPathComponent("rester")

    let process = Process()
    process.executableURL = binary
    process.arguments = [requestFile.string] + extraArguments

    let pipe = Pipe()
    process.standardOutput = pipe

    try process.run()

    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = (String(data: data, encoding: .utf8) ?? "no output")
        .maskTime
        .maskPath(requestFile)
        .maskPath(requestFile.parent)  // this is the workDir we're replacing
        .maskLine(prefix: "JSON: ")
        .maskLine(prefix: "Headers: ")
        .maskLine(prefix: "tag_name: ")
        .maskLine(prefix: "\\[0\\].id: ")
    let status = process.terminationStatus

    return (status, output)
}


extension Optional {
    func unwrapped() throws -> Wrapped {
        if let unwrapped = self {
            return unwrapped
        } else {
            throw TestError.runtimeError("attempted to unwrap nil Optional")
        }
    }
}

