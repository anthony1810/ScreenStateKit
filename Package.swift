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
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ScreenStateKit",
            path: "Sources/ScreenStatetKit"
        ),
        .testTarget(
            name: "ScreenStateKitTests",
            dependencies: [
                "ScreenStateKit",
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
            ],
            path: "Tests/ScreenStatetKitTests",
            exclude: ["ScreenStateKit.xctestplan"]
        ),
    ]
)