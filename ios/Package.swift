// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DietApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DietApp",
            targets: ["DietApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0"),
        .package(url: "https://github.com/clerk/clerk-ios", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "DietApp",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Clerk", package: "clerk-ios")
            ],
            path: "Sources/DietApp"
        )
    ]
)
