// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rester",
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Files.git", from: "2.0.0"),
        .package(url: "https://github.com/crossroadlabs/Regex.git", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Rester",
            dependencies: ["Files", "Regex", "Yams"]),
        .testTarget(
            name: "ResterTests",
            dependencies: ["Rester"]),
    ]
)
