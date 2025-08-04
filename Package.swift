// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TranscriptDebugMenu",
    platforms: [.iOS(.v26), .macOS(.v26), .macCatalyst(.v26), .visionOS(.v26)],
    products: [
        .library(
            name: "TranscriptDebugMenu",
            targets: ["TranscriptDebugMenu"]
        ),
    ],
    targets: [
        .target(
            name: "TranscriptDebugMenu"
        ),
        .testTarget(
            name: "TranscriptDebugMenuTests",
            dependencies: ["TranscriptDebugMenu"]
        ),
    ]
)
