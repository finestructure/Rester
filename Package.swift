// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Rester",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15)
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
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.8.1"),
        .package(url: "https://github.com/PromiseKit/Foundation.git", from: "3.3.4"),
    ],
    targets: [
        .executableTarget(
            name: "Rester",
            dependencies: ["ResterCore"]),
        .target(
            name: "ResterCore",
            dependencies: [
                "Commander",
                .product(name: "Gen", package: "swift-gen"),
                "LegibleError",
                .product(name: "Path", package: "Path.swift"),
                .product(name: "PMKFoundation", package: "Foundation"),
                "PromiseKit", "Rainbow", "Regex", "ValueCodable", "Yams"
            ]
        ),
        .testTarget(
            name: "ResterTests",
            dependencies: [
                "ResterCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            exclude: ["__Snapshots__", "TestData"]
        ),
    ]
)
