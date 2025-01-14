// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Mantis",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(
            name: "Mantis",
            targets: ["Mantis", "MantisUtils"]
        ),
        .library(name: "MantisUtils", targets: ["MantisUtils"])
    ],
    targets: [
        .target(
            name: "Mantis",
            dependencies: ["MantisUtils"],
            exclude: ["Info.plist", "Resources/Info.plist"],
            resources: [.process("Resources")],
            swiftSettings: [.define("MANTIS_SPM")]
        ),
        .target(name: "MantisUtils")
    ]
)
