// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SReader",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SReader",
            targets: ["SReader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nbhasin2/GCDWebServer.git", from: "3.5.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SReader",
            dependencies: [
                .product(name: "GCDWebServers", package: "GCDWebServer"),
            ],
            resources: [
                .copy("scripts"),
            ],
            swiftSettings: [
                .swiftLanguageVersion(.v6),
            ]),
    ])
