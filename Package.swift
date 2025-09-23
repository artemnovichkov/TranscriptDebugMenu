// swift-tools-version: 6.0
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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "TranscriptDebugMenu",
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
