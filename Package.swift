// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rester",
    products: [
        .executable(name: "rester", targets: ["Rester"])
    ],
    dependencies: [
        .package(url: "https://github.com/crossroadlabs/Regex.git", from: "1.2.0"),
        .package(url: "https://github.com/finestructure/ValueCodable", from: "0.0.2"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "1.0.0"),
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
        .package(url: "https://github.com/mxcl/LegibleError.git", from: "1.0.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.0.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-gen.git", from: "0.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.3.0"),
        .package(url: "https://github.com/PromiseKit/Foundation.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "Rester",
            dependencies: ["ResterCore"]),
        .target(
            name: "ResterCore",
            dependencies: ["Commander", "Gen", "LegibleError", "Path", "PMKFoundation", "PromiseKit", "Rainbow", "Regex", "ValueCodable", "Yams"]),
        .testTarget(
            name: "ResterTests",
            dependencies: ["ResterCore", "SnapshotTesting"]),
    ]
)
