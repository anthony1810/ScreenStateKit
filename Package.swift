// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenStateKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ScreenStateKit",
            targets: ["ScreenStateKit"]),
    ],
    targets: [
        .target(
            name: "ScreenStateKit",
            path: "Sources/ScreenStatetKit"
        ),
        .testTarget(
            name: "ScreenStateKitTests",
            dependencies: [
                "ScreenStateKit"
            ],
            path: "Tests/ScreenStatetKitTests",
            exclude: ["ScreenStateKit.xctestplan"]
        ),
    ]
)