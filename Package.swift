// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Rester",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_10),
        .tvOS(.v10)
    ],
    products: [
        .executable(name: "rester", targets: ["Rester"]),
        .library(name: "ResterCore", targets: ["ResterCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/crossroadlabs/Regex.git", from: "1.2.0"),
        .package(url: "https://github.com/finestructure/ValueCodable", from: "0.1.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0"),
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
        .package(url: "https://github.com/mxcl/LegibleError.git", from: "1.0.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.0.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-gen.git", from: "0.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .exact("1.7.2")),
        .package(url: "https://github.com/PromiseKit/Foundation.git", from: "3.3.4"),
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
