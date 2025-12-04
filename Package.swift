// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenStatetKit",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ScreenStatetKit",
            targets: ["ScreenStatetKit"]),
    ],
    targets: [
        .target(
            name: "ScreenStatetKit"
        ),
        .testTarget(
            name: "ScreenStatetKitTests",
            dependencies: [
                "ScreenStatetKit"
            ]
        ),
    ]
)
