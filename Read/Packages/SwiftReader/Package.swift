// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftReader",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "SwiftReader",
            targets: ["SwiftReader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nbhasin2/GCDWebServer.git", from: "3.5.5"),
    ],
    targets: [
        .target(
            name: "SwiftReader",
            dependencies: [
                .product(name: "GCDWebServers", package: "GCDWebServer"),
            ],
            resources: [
                .copy("scripts"),
            ]),
        .testTarget(
            name: "SwiftReaderTests",
            dependencies: ["SwiftReader"]),
    ])
