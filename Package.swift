// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIFlow",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftUIFlow",
            targets: ["SwiftUIFlow"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIFlow",
            path: "SwiftUIFlow",
            exclude: [
                "SwiftUIFlow.docc"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "SwiftUIFlowTests",
            dependencies: ["SwiftUIFlow"],
            path: "SwiftUIFlowTests"
        )
    ]
)
